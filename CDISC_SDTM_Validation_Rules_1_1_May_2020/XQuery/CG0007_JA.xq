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

(: Rule CG0007 - --DY variable may only be populated when RFSTDTC is a complete date and the --DTC is at least a complete date:
Precondition: The date portion of --DTC != complete date or the date portion of DM.RFSTDTC != complete date
Rule: --DY = null
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
(: iterate over all other datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[not(@Name='DM')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: Get the OIDs of the --DY and --DTC variables  :)
    let $dyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DY') and string-length(@Name)=4]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dyname := concat($name,'DY')
    let $dtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DTC') and string-length(@Name)=5]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    ) 
    let $dtcname := $definedoc//odm:ItemDef[@OID=$dtcoid]/@Name 
    (: and the OID of the USUBJID variable (might be different from the one in DM) :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: get the --DTC value :)
        let $dtcvalue := $record/odm:ItemData[@ItemOID=$dtcoid]/@Value
        (: and check whether it is a complete date - i.e. string-length at least 10 :)
        let $iscompletedtcvalue := string-length($dtcvalue) >= 10  (: boolean :)
        (: look up the record in the DM dataset and get the RFSTDTC :)
        (: keeping worst case scenario into account that there are two records for the same USUBJID in DM - take the first :)  
        let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: and check whether also RFSTDTC is complete :)
        let $iscompleterfstdtcvalue := string-length($rfstdtcvalue) >= 10 (: boolean :)
        let $dyvalue := $record/odm:ItemData[@ItemOID=$dyoid]/@Value
        (: when one of RFSTDTC and xxDTC is not complete, there may NOT be a xxDY value :)
        where (not($iscompletedtcvalue) or not($iscompleterfstdtcvalue)) and $dyvalue
        return <error rule="CG0007" dataset="{data($name)}" variable="{data($dyname)}" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">{data($dyname)} is present (value={data($dyvalue)}) although one of {data($dtcname)} (value={data($dtcvalue)}) or RFSTDTC (value={data($rfstdtcvalue)}) is not a complete date</error> 	
