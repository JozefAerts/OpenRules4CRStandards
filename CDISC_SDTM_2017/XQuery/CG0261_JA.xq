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

(: Rule CG0261 - when TSVAL1 != null then TSVAL != null :)
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
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: get the OIDs of TSVAL and of TSVAL1 :)
    let $tsvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID
        where $a =$itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsval1oid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVAL1']/@OID
        where $a =$itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of TSVAL and of TSVAL1 (if any) :)
        let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
        let $tsval1 := $record/odm:ItemData[@ItemOID=$tsval1oid]/@Value
        (: when TSVAL1 is populated the TSVAL must be populated :)
        where string-length($tsval1)>0 and not($tsval or string-length($tsval)>0)
        return <error rule="CG0261" dataset="TS" variable="TSVAL" recordnumber="{data($recnum)}" rulelastupdate="2017-02-26">TSVAL1='{data($tsval1)}' is populated but TSVAL=null</error>			
		
		