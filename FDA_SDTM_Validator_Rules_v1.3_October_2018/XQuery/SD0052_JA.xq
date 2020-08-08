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
	
(: Rule SD0052 - Inconsistent value for VISITNUM within VISIT
All values of Visit Number (VISITNUM) should be the same for a given value of Visit Name (VISIT)
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
(: Iterate over the TV and VS datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='TV' or @Name='SV']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OID of VISITNUM and VISIT :)
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $visitoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: get all unique VISIT values within the dataset :)
    let $uniquevisitvalues := distinct-values(doc($datasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$visitoid]/@Value)
        (: iterate over these unique VISIT values and for each of them, find all records - also all with the same value for VISIT :)
        for $uniquevisit in $uniquevisitvalues
            let $records := doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$visitoid][@Value=$uniquevisit]]
            (: now get the distinct values for VISIT within each VISITNUM :)
            let $uniquevisitnumvalues := distinct-values($records/odm:ItemData[@ItemOID=$visitnumoid]/@Value)
            (: the number of unique VISITNUM values for each VISIT must be 1 :)
            let $uniquevisitnumvaluescount := count($uniquevisitnumvalues)
            where $uniquevisitnumvaluescount != 1
            return <error rule="SD0052" dataset="{data($name)}" variable="VISITNUM" rulelastupdate="2020-08-08">Inconsistent value for VISITNUM within VISIT={data($uniquevisit)} in dataset {data($datasetname)}. {data($uniquevisitnumvaluescount)} different combinations were found</error>
			