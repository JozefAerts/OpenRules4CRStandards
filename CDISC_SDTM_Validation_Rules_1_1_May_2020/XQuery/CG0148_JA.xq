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

(: Rule CG0148 - When EX dataset present in study then RFXSTDTC = earliest EX.EXSTDTC for that subject :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: sorting function - also sorts dates :)
declare function functx:sort
  ( $seq as item()* )  as item()* {

   for $item in $seq
   order by $item
   return $item
 } ;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
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
(: get the OID of RFXSTDTC in DM :)
let $rfxstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFXSTDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: we also need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: get the EX dataset and its location :)
let $exitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='EX']
let $exdatasetlocation := (
	if($defineversion='2.1') then $exitemgroupdef/def21:leaf/@xlink:href
	else $exitemgroupdef/def:leaf/@xlink:href
)
let $exdatasetdoc := doc(concat($base,$exdatasetlocation))
(: and the OID of EXSTDTC :)
let $exstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='EXSTDTC']/@OID 
    where $a = $exitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: we also need the OID of USUBJID in EX :)
let $exusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $exitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all the records in DM that have a value for RFXENDTC :)
for $dmrecord in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rfxstdtcoid]]
    let $recnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of USUBJID and of RFXSTDTC :)
    let $dmusubjid := $dmrecord/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    let $rfxstdtc := $dmrecord/odm:ItemData[@ItemOID=$rfxstdtcoid]/@Value
    (: get all the EXSTDTC and EXENDTC values in DS for this subject :)
    let $exstdtcvalues := $exdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$exusubjidoid and @Value=$dmusubjid]]/odm:ItemData[@ItemOID=$exstdtcoid]/@Value
    (: and the latest of them :)
    let $earliestexstdtc := functx:sort($exstdtcvalues)[1]
    (: RFXSTDTC = earliest value of EX.EXSTDTC :)
    where not($rfxstdtc=$earliestexstdtc)
    return <error rule="CG0148" variable="RFXENDTC" dataset="DM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">RFXSTDTC='{data($rfxstdtc)}' does not correspond to the earliest exposure EXSTDTC='{data($earliestexstdtc)}' value</error>				
		
	