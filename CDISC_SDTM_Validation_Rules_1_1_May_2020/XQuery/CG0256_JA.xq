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

(: Rule CG0256 - When TIVERS not present in dataset then IETESTCD unique in dataset :)
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
(: Get the TI dataset :)
let $tidatasetdef := $definedoc//odm:ItemGroupDef[@Name='TI']
let $tidatasetname := $tidatasetdef/def:leaf/@xlink:href
let $tidatasetdoc := doc(concat($base,$tidatasetname))
(: get the OID of IETESTCD and TIVERS variables (when present) :)
let $ietestcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETESTCD']/@OID 
        where $a = $tidatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $tiversoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TIVERS']/@OID 
        where $a = $tidatasetdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in TI but only when TIVERS is not present / not defined in the define.xml :)
for $record in $tidatasetdoc[$ietestcdoid and not($tiversoid)]//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of IETESTCD :)
    let $ietestcd := $record/odm:ItemData[@ItemOID=$ietestcdoid]/@Value
    (: iterate over all the subsequent records :)
    for $recordnext in $record/following-sibling::odm:ItemGroupData
        let $recnumnext := $recordnext/@data:ItemGroupDataSeq
        (: get the value of IETESTCD in this subsequent record :)
        let $ietestcdnext := $recordnext/odm:ItemData[@ItemOID=$ietestcdoid]/@Value
        (: give an error when the 2 values of IETEST are identical :)
        where $ietestcd=$ietestcdnext
        return <error rule="CG0256" dataset="TI" variable="IETESTCD" rulelastupdate="2020-06-15" recordnumber="{data($recnum)}">Records {data($recnum)} and {data($recnumnext)} have the same value for IETESTCD='{data($ietestcd)}' where TIVERS is absent</error>			
		
	