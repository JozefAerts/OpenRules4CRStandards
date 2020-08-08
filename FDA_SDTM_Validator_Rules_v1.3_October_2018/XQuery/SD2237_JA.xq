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
	
(: Rule SD2237: A value for an Actual Arm (ACTARM) variable is expected to be equal to a value of an Arm (ARM) variable :)
(: FDA Technical Conformance Guide March 2019:
Screen failures, when provided, should be included as a record in DM with the ARM, ARMCD, ACTARM, and ACTARMCDfield left blank. 
For subjects who are randomized in treatment group but not treated, the planned arm variables (ARM and ARMCD) should be populated,
but actual treatment arm variables (ACTARM and ACTARMCD) should be left blank
:)
(: Rule violates conformance guide for non-treated but randomized subjects (March 2019) :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
    let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARM and of ARM :)
    let $actarmoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $armoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARM and of ARM :)
        let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
        let $armvalue := $record/odm:ItemData[@ItemOID=$armoid]/@Value
        (: give a INFO when ACTARM != ARM :)
        where not($actarmvalue = $armvalue)
        return <info dataset="DM" variable="ACTARM" rule="SD2237" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">ACTARM, value='{data($actarmvalue)}' does not equal ARM, value='{data($armvalue)}'</info>	
