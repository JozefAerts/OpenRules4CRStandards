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

(: Rule CG0531 - When RACE = MULTIPLE, then Multiple SUPPDM.QNAM records exist for the subject :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := (
	if($defineversion='2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the location of the SUPPDM dataset :)
let $suppdmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SUPPDM']
let $suppdmdatasetlocation := (
	if($defineversion='2.1') then $suppdmitemgroupdef/def21:leaf/@xlink:href
	else $suppdmitemgroupdef/def:leaf/@xlink:href
)
(: get the SUPPDM documentm, when there is one :)
let $suppdmdatasetdoc := (
	if($suppdmdatasetlocation) then doc(concat($base,$suppdmdatasetlocation))
	else ()
)
(: in DM, we need the OID of USUBJID and of RACE :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $raceoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RACE']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
) 
(: in SUPPDM, we need to the OID of USUBJID, QNAM. We do not need QVAL :)
let $suppdmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $suppdmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $qnamoid := (
    for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID 
    where $a = $suppdmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: Iterate over the records in DM for which RACE='MULTIPLE' :)
for $dmrecord in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID='$raceoid' and @Value='MULTIPLE']]
    let $recnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of USUBJID and of RACE :)
    let $usubjid := $dmrecord/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    let $race := $dmrecord/odm:ItemData[@ItemOID=$raceoid]/@Value
    (: count the number of records in SUPPDM for this subject for which QNAM starts-with 'RACE' :)
    let $suppdmcountrace := count($suppdmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$suppdmusubjidoid and @Value=$usubjid] and odm:ItemData[@ItemOID=$qnamoid and starts-with(@Value,'RACE')]])
    (: there must be at least 2 SUPPDM records :)
    where $suppdmcountrace < 2 
    return <error rule="CG0531" variable="RACE" dataset="DM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Only {data($suppdmcountrace)} 'RACE' records for USUBJID='{data($usubjid)}' have been found in SUPPDM for DM.RACE='{data($race)}'</error>				
	
	