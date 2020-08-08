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
	
(: Rule SD1205 ECSTDTC/EXSTDTC date is before RFXSTDTC :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $datasetname := 'EX' :)
let $definedoc := doc(concat($base,$define))
(: get the DM dataset :)
let $dmdatasetname := ( 
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdataset := concat($base,$dmdatasetname)
(: get the OIDs of USUBJID and RFXSTDTC :)
let $usubjoiddm := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
let $rfxstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFXSTDTC']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: return <test>{data($usubjoid)} - {data($rfxstdtcoid)}</test>):)
(: create a temporary structure containing USUBJID and RFXSTDTC :)
let $usubjidrfxstdtcpairs := (
    for $record in doc($dmdataset)//odm:ItemGroupData
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjoiddm]/@Value
        let $rfxstdtc := $record/odm:ItemData[@ItemOID=$rfxstdtcoid]/@Value
    return <record usubjid="{$usubjid}" rfxstdtc="{$rfxstdtc}" />
)
(: get the OID of EXSTDTC or EGSTDTC :)
let $stdtcname := concat($datasetname,'STDTC')
let $stdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name=$stdtcname]/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name=$datasetname and (@Name='EC' or @Name='EX')]/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of USUBJID in EX or EC :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name=$datasetname]/odm:ItemRef/@ItemOID
    return $a
)
(: get the EX or EC dataset :)
let $ecexdataset := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Name='EX' or @Name='EC']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Name='EX' or @Name='EC']/def:leaf/@xlink:href
)
let $ecexdoc := doc(concat($base,$ecexdataset))
(: now iterate over all records in EX or EC that have a --STDTC :)
for $record in $ecexdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid]]
    (: get the value of --STDTC :)
    let $stdtcvalue := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
    (: get the value of USUBJID :)
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    let $rfxstdtcvalue := $usubjidrfxstdtcpairs[@usubjid=$usubjidvalue]/@rfxstdtc
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and compare with the value of RFXSTDTC in DM for the same USUBJID :)
    where $rfxstdtcvalue and xs:date($rfxstdtcvalue) > xs:date($stdtcvalue) 
    (: and when the STDTC is before RFXSTDTC give an error :)
    return <error rule="SD1205" dataset="{$datasetname}" variable="{$stdtcname}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">{data($stdtcname)} date '{data($stdtcvalue)}' is before RFXSTDTC '{data($rfxstdtcvalue)}'</error>

