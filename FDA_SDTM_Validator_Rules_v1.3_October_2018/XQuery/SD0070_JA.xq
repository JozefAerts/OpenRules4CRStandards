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

(: Rule SD0070 - No Exposure record found for subject:
All Demographics (DM) subjects (USUBJID) participating in a study that includes investigational product should have at least one record in the Exposure (EX) domain, except for subjects who failed screening (ARMCD = 'SCRNFAIL') or were not fully assigned to an Arm (ARMCD = 'NOTASSGN')
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
let $dmdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdataset := concat($base,$dmdatasetname)
(: Get the EX dataset :)
let $exdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='EX']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='EX']/def:leaf/@xlink:href
)
let $exdataset := concat($base,$exdatasetname)
(: and the OID of the USUBJID and of ARMCD in the DM dataset :) 
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: Attention, there can be more than 1 of them - although bad practice :)
(: let $armcdoid := $definedoc//odm:ItemDef[@Name='ARMCD']/@OID :)
(: better and surer :)
let $armcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: we also need the OID of USUBJID in the EX dataset :)
let $exusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='EX']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over the DM dataset and  :)
for $record in doc($dmdataset)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: $hasarmassigned sets whether the subject has been assigned tom an arm :)
    let $hasarmassigned := not($record/odm:ItemData[@ItemOID=$armcdoid]/@Value = 'SCRNFAIL' or  $record/odm:ItemData[@ItemOID=$armcdoid]/@Value = 'NOTASSGN')
    (: now count the number of records for this subject in the DS dataset :)
    let $count := count(doc($exdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$exusubjidoid and @Value=$usubjidvalue]])
    let $arm := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
    where $hasarmassigned and $count = 0
    (: and now check whether there are any records in the DS dataset  :)
    return <warning rule="SD0070" rulelastupdate="2020-08-08" dataset="DM" variable="USUBJID" recordnumber="{data($recnum)}">No exposure records were found in dataset {data($exdatasetname)} for subject {data($usubjidvalue)} with assigned arm {data($arm)}</warning>
