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

(: Rule SD0032: Missing value for --TPT, when --TPTNUM is provided :)
(: Applies to: INTERVENTIONS, EVENTS, FINDINGS, CO :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the INTERVENTIONS, EVENTS, FINDINGS, and CO datasets :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'
		or @Domain='CO']
    let $name := $itemgroupdef/@Name
    (: get the dataset location and the dataset document itself :)
	let $datasetname := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and get the OID of --TPT and of --TPTNUM and their name :)
    let $tptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
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
    (: iterate over all the records in the dataset that have --TPTNUM populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptnumoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --TPTNUM :)
        let $tptnum := $record/odm:ItemData[@ItemOID=$tptnumoid]/@Value
        (: get the value of --TPT (if any) :)
        let $tpt := $record/odm:ItemData[@ItemOID=$tptoid]/@Value
        (: --TPT must be populated :)
        where not($tpt)
        return <error rule="SD0032" rulelastupdate="2019-08-23" dataset="{data($name)}" variable="{data($tptname)}" recordnumber="{data($recnum)}">Variable {data($tptname)} is not populated although variable {data($tptnumname)} is populated, value={data($tptnum)} </error>				
	
	