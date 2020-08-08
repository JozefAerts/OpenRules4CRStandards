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
	
(: Rule SD0023 - Missing value for --STAT, when --REASND is provided:
Completion Status (--STAT) should be set to 'NOT DONE', when Reason Not Done (--REASND) is populated
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
(: Find all "Findings", "Interventions" and "Events" datasets  :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='FINDINGS' or upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='FINDINGS' or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the STAT and REASND variables :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    let $reasndoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'REASND')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $reasndname := $definedoc//odm:ItemDef[@OID=$reasndoid]/@Name
    (: iterate over each record in the dataset for which there is a REASND data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$reasndoid]]
        (: get the record number and the value for REASND :)
        let $recnum := $record/@data:ItemGroupDataSeq
        let $reasndvalue := $record/odm:ItemData[@ItemOID=$reasndoid]/@Value
        (: and check whether there is a corresponding xxSTAT :)
        let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        (: check whether xxSTAT is absent or deviates from 'NOT DONE' :)
        where not($statvalue) or  not($statvalue='NOT DONE') 
        return <warning rule="SD0023" dataset="{data($name)}" variable="{data($statname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum}">Missing or invalid value for {data($statname)} when {data($reasndname)} is provided - {data($reasndname)}={data($reasndvalue)} - {data($statname)}={data($statvalue)} in dataset {data($datasetname)}</warning>	
