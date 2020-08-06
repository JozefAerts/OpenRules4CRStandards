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
		
(: Rule SD1033 - Inconsistent value for ARM: 
A value for Description of Planned Arm (ARM) must have a unique value for Planned Arm Code (ARMCD) with the domain DM, TA, TV
:)
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
(: Iterate over the DM, TA and TV datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM' or @Name='TA' or @Name='TV']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and get the OID of ARMCD and ARM :)
    let $armcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $armoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: get all unique ARMCD values within the dataset :)
    let $uniquearmcdvalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$armcdoid]/@Value)
        (: iterate over these unique ARMCD values and for each of them, find all records - also all with the same value for ARMCD:)
        for $uniquearmcd in $uniquearmcdvalues
            let $records := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid][@Value=$uniquearmcd]]
            (: now get the distinct values for ARM within each ARMCD :)
            let $uniquearmvalues := distinct-values($records/odm:ItemData[@ItemOID=$armoid]/@Value)
            (: the number of unique ARM values for each ARMCD must be 1 :)
            let $uniquearmvaluescount := count($uniquearmvalues)
            where $uniquearmvaluescount != 1 
            return <error rule="SD1033" dataset="{data($name)}" variable="ARM" rulelastupdate="2019-08-14">Inconsistent value for ARM within ARMCD={data($uniquearmcd)} in dataset {data($datasetname)}. {data($uniquearmvaluescount)} different combinations were found</error>		
