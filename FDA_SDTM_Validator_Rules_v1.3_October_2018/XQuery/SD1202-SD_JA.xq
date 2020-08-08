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

(: Rule SD1202: --STDTC date is after RFPENDTC :)
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
(: get the DM dataset and the OID of DM.RFPENDTC (datetime of end of participation) :)
let $dmdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and get the location and the DM document itself :)
let $dmlocation := ( 
	if($defineversion = '2.1') then $dmdef/def21:leaf/@xlink:href
	else $dmdef/def:leaf/@xlink:href
)
let $dmdoc := doc(concat($base,$dmlocation))
(: we also need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: and of RFPENDTC :)
let $rfpendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFPENDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: create a temporary structure containing USUBJID and RFPENDTC :)
let $usubjidrfpendtcpairs := (
    for $record in $dmdoc//odm:ItemGroupData
        let $usubjid := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
        let $rfpendtc := $record/odm:ItemData[@ItemOID=$rfpendtcoid]/@Value
    return <record usubjid="{$usubjid}" rfpendtc="{$rfpendtc}" />
)
(: iterate over the provided dataset in classes INTERVENTIONS, EVENTS, FINDINGS, DM, SE, SV datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    (: get the dataset name :)
    let $name := $datasetdef/@Name
	let $domain := $datasetdef/@Domain
    (: get the datasetlocation :)
    let $datasetlocation := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: we need the OID of USUBJID and of the --STDTC variable :)
    let $stdtcvarname := concat($domain,'STDTC')
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name=$stdtcvarname]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: now iterate over all records that do have a value for --STDTC :)
    for $record in doc(concat($base,$datasetlocation))//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STDTC and of USUBJID :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $stdtcvalue := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
        (: get the value of RFPENDTC in DM :)
        let $rfpendtcvalue := $usubjidrfpendtcpairs[@usubjid=$usubjidvalue]/@rfpendtc
        (: take care of incomplete dates :)
        let $stdtctestvalue :=
                (: only the year is given :)
                if(string-length($stdtcvalue) = 4) then concat($stdtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($stdtcvalue) = 7) then concat($stdtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                else if(string-length($stdtcvalue) = 10) then concat($stdtcvalue,'T00:00:00')
                        (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($stdtcvalue) = 11) then concat($stdtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($stdtcvalue) = 13) then concat($stdtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($stdtcvalue) = 16) then concat($stdtcvalue,':00')
                (: all ok anyway :)
                else ($stdtcvalue)
        (: and also for RFPENDTC :)
        let $rfpendtctestvalue := (
            (: only the year is given :)
                if(string-length($rfpendtcvalue) = 4) then concat($rfpendtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($rfpendtcvalue) = 7) then concat($rfpendtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                else if(string-length($rfpendtcvalue) = 10) then concat($rfpendtcvalue,'T00:00:00')
                        (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($rfpendtcvalue) = 11) then concat($rfpendtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($rfpendtcvalue) = 13) then concat($rfpendtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($rfpendtcvalue) = 16) then concat($rfpendtcvalue,':00')
                (: all ok anyway :)
                else ($rfpendtcvalue)
        )
        (: compare both values :)
        (: RFPENDTC value must be equal or higher than STDTC - but first check whether it really is a datetime :)
            where $stdtctestvalue castable as xs:dateTime and $rfpendtctestvalue castable as xs:dateTime and xs:dateTime($stdtctestvalue) > xs:dateTime($rfpendtctestvalue) 
            return <error rule="SD1202" dataset="{data($name)}" variable="{data($stdtcvarname)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">{data($stdtcvarname)}={data($stdtcvalue)} is after RFPENDTC={data($rfpendtcvalue)} in dataset {data($name)}</error>	

