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

(: Rule CG0255 - When TIVERS present in dataset then IETESTCD unique within TIVERS :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TI dataset :)
let $tidatasetdef := $definedoc//odm:ItemGroupDef[@Name='TI']
let $tidatasetname := (
	if($defineversion='2.1') then $tidatasetdef/def21:leaf/@xlink:href
	else $tidatasetdef/def:leaf/@xlink:href
)
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
(: iterate over all the records in TI (when present) :)
for $record in $tidatasetdoc[$ietestcdoid and $tiversoid]//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of IETESTCD and of TIVERS (if present) :)
    let $ietestcd := $record/odm:ItemData[@ItemOID=$ietestcdoid]/@Value
    let $tivers := $record/odm:ItemData[@ItemOID=$tiversoid]/@Value
    (: iterate over all the subsequent record with the same TIVERS :)
    for $recordnext in $record/following-sibling::odm:ItemGroupData[odm:ItemData[@ItemOID=$tiversoid and @Value=$tivers]]
        let $recnumnext := $recordnext/@data:ItemGroupDataSeq
        (: get the value of IETESTCD in this subsequent record with the same value for TIVERS :)
        let $ietestcdnext := $recordnext/odm:ItemData[@ItemOID=$ietestcdoid]/@Value
        (: give an error when the 2 values of IETEST for the same value of TIVERS are identical :)
        where $ietestcd=$ietestcdnext
        return <error rule="CG0255" dataset="TI" variable="IETESTCD" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Records {data($recnum)} and {data($recnumnext)} have the same value for IETESTCD='{data($ietestcd)}' and TIVERS={data($tivers)}</error>			
		
	