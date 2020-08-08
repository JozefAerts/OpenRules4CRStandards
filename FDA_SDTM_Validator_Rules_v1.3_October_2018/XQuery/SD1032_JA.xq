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
	
(: Rule SD1032 - No records for 'SCRNFAIL' subject are found in IE domain:
All subjects with Planned Arm Code (ARMCD) equals 'SCRNFAIL' should have records in the Inclusion/Exclusion Criteria Not Met (IE) domain
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
(: iterate over all records in the DM datasets :)
let $dmdataset := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetname := (
	if($defineversion = '2.1') then $dmdataset/def21:leaf/@xlink:href
	else $dmdataset/def:leaf/@xlink:href
)
let $dmdatasetlocation:= concat($base,$dmdatasetname)
(: and get the OIDs of USUBJID and ARMCD :)
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
(: Get the IE data :)
let $iedataset := $definedoc//odm:ItemGroupDef[@Name='IE']
let $iedatasetname := (
	if($defineversion = '2.1') then $iedataset/def21:leaf/@xlink:href
	else $iedataset/def:leaf/@xlink:href
)
let $iedatasetlocation := concat($base,$iedatasetname)
(: and the OID of the USUBJID in the IE dataset :)
let $ieusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
    return $a
)
(: get the records for which ARMCD=SCRNFAIL :)
for $record in doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid][@Value='SCRNFAIL']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the USUBJID of this record :)
    let $dmusubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: and count the number of records for this subject in the IE dataset :)
    let $ierecordcount := count(doc($iedatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$ieusubjidoid][@Value=$dmusubjid]])
    (: there must be at least one record in IE :)
    where $ierecordcount > 1
    return <warning rule="SD1032" dataset="DM" variable="ARMCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">No records for in IE dataset {data($iedatasetname)} for Screen Failure subject with USUBJID {data($dmusubjid)} </warning>		
