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

(: Rule CG0426 - When --STRESU != null then --STRESC (in standard units) != null :)
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
(: iterate over all FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $itemgroupdef/@Name
    (: get the dataset location and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the --STRESC and --STRESU variable :)
    let $strescoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $strescname := $definedoc//odm:ItemDef[@OID=$strescoid]/@Name
    let $stresuoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESU')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $stresuname := doc(concat($base,$define))//odm:ItemDef[@OID=$stresuoid]/@Name
    (: iterate over all records for which --STRESU is populated (not null) :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stresuoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STRESU and of --STRESC (if any)  :)
        let $stresu := $record/odm:ItemData[@ItemOID=$stresuoid]/@Value
        let $stresc := $record/odm:ItemData[@ItemOID=$strescoid]/@Value
        (: --STRESC must be populated :)
        where not($stresc)
        return <error rule="CG0426" dataset="{data($name)}" variable="{data($strescname)}" rulelastupdate="2017-03-22" recordnumber="{data($recnum)}">{data($stresuname)}='{data($stresu)}' is not NULL, but {data($strescname)}=NULL</error>			
		
		