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

(: Rule CG0540: When DM.ACTARMCD not null, then DS records present for subject :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the DS dataset definition :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the DS dataset location and document :)
let $dsdatasetlocation := (
	if($defineversion='2.1') then $dsitemgroupdef/def21:leaf/@xlink:href
	else $dsitemgroupdef/def:leaf/@xlink:href
)
let $dsdoc := (
	if($dsdatasetlocation) then doc(concat($base,$dsdatasetlocation))
    else() (: No DS dataset has been defined - it is absent :)
)
(: get the DM dataset definition :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the DM dataset location and document :)
let $dmdatasetlocation := (
	if($defineversion='2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdoc := (
	if($dmdatasetlocation) then doc(concat($base,$dmdatasetlocation))
    else() (: No DM dataset has been defined - it is absent :)
)
(: we need the OIDs of USUBJID in DS and DM :)
let $dsusubjidoid := (
	for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
	where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
	return $a
)
let $dmusubjidoid := (
	for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
	where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
	return $a
)
(: We also need the OID of the ACTARMCD variable in DM :)
let $dmactarmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ACTARMCD']/@OID 
	where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
	return $a
)
(: Now iterate over all records that have DM.ACTARMCD not null :)
for $record in $dmdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmactarmcdoid]]
	let $dmrecnum := $record/@data:ItemGroupDataSeq
    (: get USUBJID value :)
    let $dmusubjidvalue := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    (: get the value of ACTARMCD for reporting :)
    let $actarmcdvalue := $record/odm:ItemData[@ItemOID=$dmactarmcdoid]/@Value
    (: now count the number of DS records for this subject (i.e. having the same USUBJID value) :)
    let $numdsrecords := count($dsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$dmusubjidvalue]])
    (: there must be at least 1 DS record for this subject :)
    where $numdsrecords = 0
    return <error rule="CG0540" dataset="DS" rulelastupdate="2020-08-04">No DS records were found for DM subject with USUBJID='{data($dmusubjidvalue)}' with ACTARMCD='{data($actarmcdvalue)}'</error>
	
	