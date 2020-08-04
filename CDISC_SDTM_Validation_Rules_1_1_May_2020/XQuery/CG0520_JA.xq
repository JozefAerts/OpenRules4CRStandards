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

(: Rule CG0520: DM: When ARMCD ^=null and ACTARMCD ^=null, then ARMNRS = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: get the OID of the ARMCD, ACTARMCD and of ARMNRS :)
    let $armcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $actarmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $armnrsoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMNRS']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that do have ARMCD and ACTARMCD populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid] and odm:ItemData[@ItemOID=$actarmcdoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of ACTARMCD and ARMCD :)
        let $actarmcdvalue := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
        let $armcdvalue := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
        (: get the value of ARMNRS (if any) :)
        let $armnrsvalue := $record/odm:ItemData[@ItemOID=$armnrsoid]/@Value
        (: give an error when ARMNRS is  populated :)
        where $armnrsvalue
        return <error rule="CG0520" dataset="DM" variable="ARM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">ARMNRS is populated although values for ACTARMCD '{}' and ACTARM '' are not null</error>	
	
	