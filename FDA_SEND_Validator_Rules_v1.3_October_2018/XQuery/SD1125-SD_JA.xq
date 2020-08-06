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
	
(: Rule SD1125 - Inconsistent value for --TPT within --ELTM
All values of Planned Elapsed Time (--ELTM) variable should be the same for a given value of Planned Time Point Name (--TPT) variable (Interventions, Findings, Events)
OR: there is a 1:1 relationship
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
declare variable $datasetname external;
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
(: let $datasetname := 'PC' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets within INTERVENTIONS, EVENTS, FINDINGS :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS'
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $datasetlocalname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc:= (
		if($datasetlocalname) then doc(concat($base,$datasetlocalname))
		else ()
	)
    (: and get the OIDs of --TPT and --ELTM :)
    let $tptoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    let $eltmoid := (
		for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
			where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
			return $a
    )
    let $eltmname := $definedoc//odm:ItemDef[@OID=$eltmoid]/@Name
    (: Get all unique values of --TPT :)
    let $tptuniquevalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tptoid]/@Value)
    (: iterate over the unique values and get the records :)
    for $tptuniquevalue in $tptuniquevalues
        (: get all the records :)
        let $uniquetptrecords := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptoid][@Value=$tptuniquevalue]]
        let $uniquetptrecordcount := count($uniquetptrecords)
        (: get the unique values for ELTM within each of the unique TPT values, and count them :)
        let $uniqueeltmvalues := distinct-values($uniquetptrecords/odm:ItemData[@ItemOID=$eltmoid]/@Value)
        let $uniqueeltmvaluescount := count($uniqueeltmvalues)
        (: the value of the count of unique ELTM values for each TPT must be 1 :)
        (: taking care of the case that -ELTM is not populated :)
        where $uniqueeltmvaluescount > 0 and not($uniqueeltmvaluescount = 1) 
        return <warning rule="SD1125" dataset="{data($name)}" variable="{data(eltmname)}" rulelastupdate="2020-07-01">Inconsistent value for {data($eltmname)} within {data($tptname)} in dataset {data($datasetname)}. {data($uniqueeltmvaluescount)} different {data($eltmname)} values were found for {data($tptname)}={data($tptuniquevalue)}</warning>		
