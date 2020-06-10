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

(: QLABEL value length <= 40 :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all SUPPQUAL datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $itemgroupdef/@Name
    (: get the OID of QLABEL :)
    let $qlabeloid := (
        for $a in $definedoc//odm:ItemDef[@Name='QLABEL']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset - QLABEL is a required variable :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of QLABEL :)
        let $qlabel := $record/odm:ItemData[@ItemOID=$qlabeloid]/@Value
        (: QLABEL may not be more than 40 characters :)
        where string-length($qlabel) > 40
        return <error rule="CG0416" dataset="{data($name)}" variable="QLABEL" rulelastupdate="2017-03-22" recordnumber="{data($recnum)}">Value of QLABEL='{data($qlabel)}' has more than 40 characters</error>														
		
		