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

(: Rule CG0247 - TAETORD is unique within an ARM :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TA datasets :)
let $tadatasetdef := $definedoc//odm:ItemGroupDef[@Name='TA']
let $tadatasetname := $tadatasetdef/def:leaf/@xlink:href
let $tadatasetdoc := doc(concat($base,$tadatasetname))
(: also need to find out the OID of ARM and of TAETORD :)
let $armoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $tadatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $taetordoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TAETORD']/@OID 
        where $a = $tadatasetdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the TA dataset :)
for $record in $tadatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of ARM and of TAETORD :)
    let $taetord := $record/odm:ItemData[@ItemOID=$taetordoid]/@Value
    let $arm := $record/odm:ItemData[@ItemOID=$armoid]/@Value
    (: iterate over all subsequent records with the same ARM value :)
    for $recordnext in $record/following-sibling::odm:ItemGroupData[odm:ItemData[@ItemOID=$armoid and @Value=$arm]]
        let $recnum2 := $recordnext/@data:ItemGroupDataSeq
        (: get the value of TAETORD in this subsequent record with the same value for ARM  :)
        let $taetord2 := $recordnext/odm:ItemData[@ItemOID=$taetordoid]/@Value
        (: give an error when both values of TAETORD are equal :)
        where $taetord=$taetord2
        return <error rule="CG0247" dataset="TA" variable="TAETORD" rulelastupdate="2017-02-25" recordnumber="{data($recnum)}">Records {data($recnum)} and {data($recnum2)} have the same value for ARM='{data($arm)}' and TAETORD={data($taetord)}</error>
		
		