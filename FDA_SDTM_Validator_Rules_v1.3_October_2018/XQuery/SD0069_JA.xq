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

(: Rule SD0069 - No Disposition record found for subject:
All Demographics (DM) subjects (USUBJID) should have at least one record in the Disposition (DS) domain with only possible exceptions to Screen Failures (ARMCD='SCRNFAIL') and Not Assigned Treatment (ARMCD='NOTASSGN') subjects
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
(: Get the DM dataset :)
let $dmdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdataset := concat($base,$dmdatasetname)
(: Get the DS dataset :)
let $dsdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DS']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DS']/def:leaf/@xlink:href
)
let $dsdataset := concat($base,$dsdatasetname)
(: and the OID of the USUBJID and of ARMCD in the DM dataset :) 
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
let $armcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: we also need the OID of USUBJID in the DS dataset :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over the DM dataset and  :)
for $record in doc($dmdataset)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: $hasarmassigned sets whether the subject has been assigned to an arm :)
    let $hasarmassigned := not($record/odm:ItemData[@ItemOID=$armcdoid]/@Value = 'SCRNFAIL' or  $record/odm:ItemData[@ItemOID=$armcdoid]/@Value = 'NOTASSGN')
    (: now count the number of records for this subject in the DS dataset :)
    let $count := count(doc($dsdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$usubjidvalue]])
    let $arm := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
    where $hasarmassigned and $count = 0
    (: and now check whether there are any records in the DS dataset  :)
    return <warning rule="SD0069" rulelastupdate="2020-08-08" dataset="DM" variable="USUBJID" recordnumber="{data($recnum)}">No disposition records were found in dataset {data($dsdatasetname)} for subject {data($usubjidvalue)} with assigned arm {data($arm)}</warning>
