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

(: When VISITNUM not present in dataset and --TPTREF present in dataset, 
	then --TPT and --TPTNUM have a one-to-one relationship per unique values of --TPTREF :)
(: Single dataset implementation :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
declare variable $datasetname external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: let $datasetname := 'LB' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the provided datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: Get the OIDs of VISITNUM and --TPTREF (when present) :)
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptrefoid := (
    	for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name
    (: and of --TPT and --TPTNUM :)
    let $tptoid := (
    	for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    let $tptnumoid := (
    	for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptnumname := $definedoc//odm:ItemDef[@OID=$tptnumoid]/@Name
    (: and of USUBJID :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset and document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    (: get the dataset document, but only when VISITNUM is ABSENT,
      and TPT and TPTNUM are present :)
    let $datasetdoc := (
    	if(not($visitnumoid) and $tptnumoid and $tptoid) then doc(concat($base,$datasetlocation))
        else()
    )
    (: group all records per USUBJID and --TPTREF in the dataset :)
    let $groupedrecords := (
      for $record in $datasetdoc[not($tptrefoid)]//odm:ItemGroupData
      group by 
          $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
          $b := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value
          return element group {  
              $record
          }
	)
    (: Each group now has the same values for USUBJID and --TPTREF :)
	(: Get all unique values of -TPTNUM within the group :)
    let $tptnumuniquevalues := distinct-values($groupedrecords//odm:ItemGroupData/odm:ItemData[@ItemOID=$tptnumoid]/@Value)
    (: iterate over the unique TPTNUM values and get the records :)
    (: TODO: is there a better way? 
    	Does this cover the case that there are 2 TPTNUM values for a single TPT?  :)
    for $uniquetptnumvalue in $tptnumuniquevalues
    	let $tptrefvalue := $groupedrecords//odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$tptrefoid]/@Value
    	let $usubjidvalue := $groupedrecords//odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $uniquetptrecords := $groupedrecords//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptnumoid and @Value=uniquetptnumvalue]]
        (: now get the number of unique values of --TPT within this set of records :)
        let $uniquetptvalues := distinct-values($uniquetptrecords/odm:ItemData[@ItemOID=$tptoid]/@Value)
        (: The number of unique value of -TPT within a single -TPTNUM must be exacty 1 :)
        let $tptvaluescount := count($uniquetptvalues)
        where not(number($tptvaluescount)=1)
        return <error rule="CG0572" dataset="{data($name)}" variable="{data($tptname)}" rulelastupdate="2020-08-04">Inconsistent value for --TPT within --TPTNUM in dataset {data($name)}. {data($tptvaluescount)} different --TPT values were found for --TPTNUM={data($uniquetptnumvalue)} within {data($tptrefname)}='{data($tptrefvalue)}' and USUBJID='{data($usubjidvalue)}'</error>						
	
	