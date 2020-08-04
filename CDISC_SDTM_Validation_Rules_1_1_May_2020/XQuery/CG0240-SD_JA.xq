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

(: Rule CG0240 - --TPT and --TPTNUM have a one-to-one relationship :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all selected datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation:= concat($base,$dsname)
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
    let $tptnumuniquevalues := distinct-values(doc($datasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$tptnumoid]/@Value)
    (: iterate over the unique TPTNUM values and get the records :)
    for $tptnumuniquevalue in $tptnumuniquevalues
        (: get all the records :)
        let $uniquetptnumrecords := doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptnumoid][@Value=$tptnumuniquevalue]]
        (: get the unique values for TPT within each of the unique TPTNUM values, and count them :)
        let $uniquetptvalues := distinct-values($uniquetptnumrecords/odm:ItemData[@ItemOID=$tptoid]/@Value)
        let $uniquetptvaluescount := count($uniquetptvalues)
        (: the value of the count of unique TPT values for each TPTNUM must be 1 :)
        where not($uniquetptvaluescount = 1) 
        return <error rule="CG0240" dataset="{data($name)}" variable="{data(tptname)}" rulelastupdate="2020-08-04">Inconsistent value for {data($tptname)} within {data($tptnumname)} in dataset {data($datasetname)}. {data($uniquetptvaluescount)} different {data($tptname)} values were found for {data($tptnumname)}={data($tptnumuniquevalue)}</error>						
		
	