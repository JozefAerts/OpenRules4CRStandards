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

(: Rule CG0530: DM: When ARMNRS ^= null, then RFENDTC = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of ARMNRS and of RFENDTC :)
let $armnrsoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMNRS']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $rfendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFENDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over the records in DM :)
for $record in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of ARMNRS and of RFENDTC :)
    let $armnrsvalue := $record/odm:ItemData[@ItemOID=$armnrsoid]/@Value
    let $rfendtcvalue := $record/odm:ItemData[@ItemOID=$rfendtcoid]/@Value
    (: When ARMNRS != null then RFENDTC = null :)
    (: Give an error when ARMNRS is populated AND RFENDTC is populated :)
    where $armnrsvalue and $rfendtcvalue
    return <error rule="CG0530" variable="RFENDTC" dataset="DM" rulelastupdate="2020-06-14" recordnumber="{data($recnum)}">RFENDTC='{data($rfendtcvalue)}' may not be populated for ARMNRS='{data($armnrsvalue)}'</error>
	
	