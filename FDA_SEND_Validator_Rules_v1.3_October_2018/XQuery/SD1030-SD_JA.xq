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
	
(: TODO: not tested yet - we need a good test submission :)
(: Rule SD1030 - Value for --STRF is populated, when RFSTDTC is NULL
Start Relative to Reference Period (--STRF) should not be populated for subjects with missing value for Reference Start Date/Time (RFSTDTC)
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
(: Get the location of the DM dataset :)
let $dmdataset := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdatasetlocation := concat($base,$dmdataset)
(: get the OID of the RFSTDTC variable :)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a   
)
(: get the OID of the USUBJID variable :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a  
)
(: iterate over all the provided datasets except within INTERVENTIONS, EVENTS, FINDINGS, SE, SV :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'
		or @Domain='SE' or @Domain='SV']
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($dsname) then doc(concat($base,$dsname))
		else ()
	)
    (: get the OID of the --STRF variable (if any) :)
    let $strfoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRF')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $strfname := $definedoc//odm:ItemDef[@OID=$strfoid]/@Name
    (: get the OID of the USUBJID variable (can be different from within DM) :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a  
    )
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$strfoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $strfvalue := $record/odm:ItemData[@ItemOID=$strfoid]/@Value
        (: and get the local USUBJID :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: look up the record in the DM dataset and get the RFSTDTC value :)
        let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: in case there is no RFSTDTC value, STRF may not be populated :)
        where not($rfstdtcvalue) and $strfvalue
        return <warning rule="SD1030" dataset="{data($name)}" variable="{data($strfname)}" rulelastupdate="2019-09-16" recordnumber="{data($recnum)}">Value for {data($strfname)} is populated(value={data($strfvalue)}), when RFSTDTC is NULL in dataset {data($datasetname)}</warning>	
