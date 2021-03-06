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

(: Rule SD0012 - --STDY is after --ENDY
Study Day of Start of Event, Exposure or Observation (--STDY) must be less or equal to Study Day of End of Event, Exposure or Observation (--ENDY)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS'
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'] 
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: Get the OIDs of the --STDY and --ENDY variables :)
    let $stdyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDY')]/@OID 
        where $a = $dataset/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdyname :=  $definedoc//odm:ItemDef[@OID=$stdyoid]/@Name
    let $endyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDY')]/@OID 
        where $a = $dataset/odm:ItemRef/@ItemOID
        return $a
    )
    let $endyname :=  $definedoc//odm:ItemDef[@OID=$endyoid]/@Name
	(: iterate over all the records for which STDY and ENDY are present :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdyoid] and odm:ItemData[@ItemOID=$endyoid]]
    	let $recnum := $record/@data:ItemGroupDataSeq
    	(: get the values :)
    	let $stdyvalue := $record/odm:ItemData[@ItemOID=$stdyoid]/@Value
    	let $endyvalue := $record/odm:ItemData[@ItemOID=$endyoid]/@Value
    	(: and compare the values :)
    	where $stdyvalue castable as xs:double and $endyvalue castable as xs:double and number($stdyvalue) > number($endyvalue)
    	return <error rule="SD0012" dataset="{data($name)}" variable="{data($stdyname)}" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">{data($stdyname)}={data($stdyvalue)} is after {data($endyname)}={data($endyvalue)}</error>
