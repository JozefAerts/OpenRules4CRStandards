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
	
(: Rule SD1086 - Incorrect value for --DY variable:
Collection Study Day (--DY) variable value should be populated as defined by CDISC standards: --DY = (date portion of --DTC) - (date portion of RFSTDTC) +1 if --DTC is on or after RFSTDTC; --DY = (date portion of --DTC) - (date portion of RFSTDTC) if --DTC precedes RFSTDTC.
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
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the location of the DM dataset :)
let $dmdataset := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
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
(: make a temporary construct with USUBJID-RFSTDTC pairs: this will speed up the lookups later :)
let $usubjidrfstdtcpairs := (
    for $record in doc($dmdatasetlocation)//odm:ItemGroupData
        let $dmusubjidvalue := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
        let $rfstdtcvalue := $record/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        return <rfstdtcpair usubjid="{data($dmusubjidvalue)}" rfstdtc="{data($rfstdtcvalue)}" />
)
(: iterate over all other provided datasets within INTERVENTIONS, EVENTS, FINDINGS :)
for $dataset in $definedoc//odm:ItemGroupDef[not(@Name='DM')][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'] 
    let $name := $dataset/@Name
    let $dsname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$dsname)
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
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: get the --DTC value :)
        let $dtcvalue := $record/odm:ItemData[@ItemOID=$dtcoid]/@Value
        (: and check whether it is a complete date - i.e. string-length at least 10 :)
        let $iscompletedtcvalue := string-length($dtcvalue) >= 10  (: boolean :)
        (: look up the record in the DM dataset and get the RFSTDTC :)
        (: keeping worst case scenario into account that there are two records for the same USUBJID in DM - take the first :)  
        (: let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value :)
        (: replacement 2020-08-08: more efficient :)
        let $rfstdtcvalue := $usubjidrfstdtcpairs[@usubjid=$usubjidvalue]/@rfstdtc
        (: and check whether also RFSTDTC is complete :)
        let $iscompleterfstdtcvalue := string-length($rfstdtcvalue) >= 10 (: boolean :)
        let $dyvalue := $record/odm:ItemData[@ItemOID=$dyoid]/@Value
        (: now calculate the DY value but only when RFSTDTC and DTC have a complete date part :)
        let $dycalculated := (
            if ($iscompleterfstdtcvalue and $iscompletedtcvalue) then
                (: if there is one, we must strip off the time part :)
                let $dtcvalueshort := substring($dtcvalue,1,10)
                let $rfstdtcvalueshort := substring($rfstdtcvalue,1,10)
                let $dycalc := (
                    if($dtcvalueshort castable as xs:date and $rfstdtcvalueshort castable as xs:date) then
                        days-from-duration(xs:date($dtcvalueshort)-xs:date($rfstdtcvalueshort))
                    else()
                ) 
                return $dycalc
            else ()  (: one or both dates are not complete dates :)
        )
        (: for the FDA there is no day 0, DY can only be <0 or >0, first day is day 1 :)
        let $dycalculatedfda := (
            if($dycalculated >= 0) then
                $dycalculated + 1
            else (
                $dycalculated    
            )
        )
        (: before comparing, check that the DY value is really an integer :)
        where $dyvalue castable as xs:integer and $dycalculatedfda and $dyvalue and not($dycalculatedfda = $dyvalue) 
        return <warning rule="SD1086" dataset="{data($name)}" variable="{data($dyname)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid value for {data($dyname)}, calculated value={data($dycalculatedfda)}, provided value={data($dyvalue)}, in dataset {data($name)} </warning>	
