(: Copyright 2020 Jozef Aerts.
Licensed under the Apache License, Version 2.0 (the "License");
You may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, 
software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
:)

(: Rule CG0262 - when TSVAL(n+1) != null then TSVALn != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OIDs for ALL the TSVALn variables of which the 6th character is a number > 1 :)
    let $tsvalnoids := (
        for $a in $definedoc//odm:ItemDef[starts-with(@Name,'TSVAL') and substring(@Name,6,1) castable as xs:integer 
        and xs:integer(substring(@Name,6,1)) > 1]/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset :)
    let $tsdatasetlocation := $itemgroup/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$tsdatasetlocation))
    (: iterate over all records in the dataset  :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over the TSVALn values :)
        for $tsvalnoid in $tsvalnoids
            (: get the value of 'N' in TSVALN :)
            let $tsvalnname := $definedoc//odm:ItemDef[@OID=$tsvalnoid]/@Name
            let $n := xs:integer(substring($tsvalnname,6,1))
            (: get the value for this TSVALn :)
            let $tsvalue := $record/odm:ItemData[@ItemOID=$tsvalnoid]/@Value
            (: and the value of N-1 :)
            let $nmin1 := $n - 1
            (: recover the name and OID of TSVALN-1 :)
            let $tsvalnmin1name := concat('TSVAL',xs:string($nmin1))
            let $tsvalnmin1oid := $definedoc//odm:ItemDef[@Name=$tsvalnmin1name]/@OID
            (: and get the value of TSVALn-1 in the record :)
            let $tsvalmin1value := $record/odm:ItemData[@ItemOID=$tsvalnmin1oid]/@Value
            (: and check that the value is not null or empty :)
            where not(string-length($tsvalmin1value) > 0)
            return <error rule="CG0262" dataset="TS" variable="{data($tsvalnname)}" recordnumber="{data($recnum)}" rulelastupdate="2017-02-26">{data($tsvalnname)}='{data($tsvalue)}' but {data($tsvalnmin1name)}=null</error>			
		
		