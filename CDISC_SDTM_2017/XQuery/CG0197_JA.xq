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

(: Rule CG0197 - When PESTRESC != null then PESTRESC = PEORRES OR a dictionary coded preferred term :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the PE dataset definition :)
let $peitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='PE']
(: and the location of the dataset :)
let $pedatasetlocation := $peitemgroupdef/def:leaf/@xlink:href
let $pedatasetdoc := doc(concat($base,$pedatasetlocation))
(: get the OIDs of PESTRESC and of PEORRES :)
let $pestrescoid := (
    for $a in $definedoc//odm:ItemDef[@Name='PESTRESC']/@OID 
        where $a = $peitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $peorresoid := (
        for $a in $definedoc//odm:ItemDef[@Name='PEORRES']/@OID 
        where $a = $peitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the CodeList for PESTRESC has an associated codelist (which can be an external codelist) :)
let $pestresccodelistoid := $definedoc//odm:ItemDef[@OID=$pestrescoid]/odm:CodeListRef/@CodeListOID
let $pestresccodelist := $definedoc//odm:CodeList[@OID=$pestresccodelistoid]
(: iterate over all the records in the PE dataset for which PESTRESC != null :)
for $record in $pedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$pestrescoid and @Value]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of PESTRESC :)
    let $pestresc := $record/odm:ItemData[@ItemOID=$pestrescoid]/@Value
    (: get the value of PEORRES :)
    let $peorres := $record/odm:ItemData[@ItemOID=$peorresoid]/@Value
    (: either PEORRES=PESTRESC OR PESTRESC is coded :)
    where not($peorres=$pestresc) and not($pestresccodelist)
    (: check whether PESTRESC is in the codelist. For this we need to know whether it can come from an external codelist  :)
    return <error rule="CG0197" dataset="PE" variable="PESTRESC" rulelastupdate="2017-02-22" recordnumber="{data($recnum)}">PESTRESC='{data($pestresc)}' is not equal to PEORRES='{data($peorres)}' and PESTRESC is not coded</error>	
		
		