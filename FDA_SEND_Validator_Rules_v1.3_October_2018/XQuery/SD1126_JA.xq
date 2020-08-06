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
	
(: Rule SD1126 - Inconsistent value for --TPT within --TPTNUM
All values of Planned Time Point Name (--TPT) variable should be the same for a given value of Planned Time Point Number (--TPTNUM) variable
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
(: iterate over all datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS'
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc:= (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and get the OIDs of --TPT and --TPTNUM :)
    let $tptoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    let $tptnumoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptnumname := $definedoc//odm:ItemDef[@OID=$tptnumoid]/@Name
    (: Get all unique values of --TPTNUM :)
    let $tptnumuniquevalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tptnumoid]/@Value)
    (: iterate over the unique TPTNUM values and get the records :)
    for $tptnumuniquevalue in $tptnumuniquevalues
        (: get all the records :)
        let $uniquetptnumrecords := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptnumoid][@Value=$tptnumuniquevalue]]
        (: get the unique values for TPT within each of the unique TPTNUM values, and count them :)
        let $uniquetptvalues := distinct-values($uniquetptnumrecords/odm:ItemData[@ItemOID=$tptoid]/@Value)
        let $uniquetptvaluescount := count($uniquetptvalues)
        (: the value of the count of unique TPT values for each TPTNUM must be 1 :)
        where not($uniquetptvaluescount = 1) 
        return <warning rule="SD1126" dataset="{data($name)}" variable="{data(tptname)}" rulelastupdate="2019-08-29">Inconsistent value for {data($tptname)} within {data($tptnumname)} in dataset {data($datasetname)}. {data($uniquetptvaluescount)} different {data($tptname)} values were found for {data($tptnumname)}={data($tptnumuniquevalue)}</warning>		
