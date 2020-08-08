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

(: Rule SD1261: When SSSTRESC = 'DEAD' then SSDTC >= DM.DTHDTC :)
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
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := (
	if($defineversion = '2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: Get the SS (Subject Status) dataset and its location :)
let $ssitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SS']
let $ssdatasetlocation := (
	if($defineversion = '2.1') then $ssitemgroupdef/def21:leaf/@xlink:href
	else $ssitemgroupdef/def:leaf/@xlink:href
)
let $ssdatasetdoc := doc(concat($base,$ssdatasetlocation))
(: we need the OID of DTHDTC and of USUBJID in DM :)
let $dmdthdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DTHDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: we need the OID of SSSTRESC, SSDTC and of USUBJID in SS :)
let $ssusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $ssstresc := (
    for $a in $definedoc//odm:ItemDef[@Name='SSSTRESC']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $ssdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SSDTC']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in SS for which SSSTRESC='DEAD' :)
for $record in $ssdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ssstresc and @Value='DEAD']]
    let $recnumss := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID for this record :)
    let $ssusubjid := $record/odm:ItemData[@ItemOID=$ssusubjidoid]/@Value
    (: get the value of SSDTC for this record :)
    let $ssdtc := $record/odm:ItemData[@ItemOID=$ssdtcoid]/@Value
    (: get the DM record for this subject :)
    let $dmrecord := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$ssusubjid]]
    let $dmrecnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of DTHDTC :)
    let $dthdtc := $dmrecord/odm:ItemData[@ItemOID=$dmdthdtcoid]/@Value
    (: SSDTC >= DM.DTHDTC :)
    where $ssdtc castable as xs:date and $dthdtc castable as xs:date and not(xs:date($ssdtc) >= xs:date($dthdtc))
    return <error rule="SD1261" variable="SSDTC" dataset="SS" recordnumber="{data($recnumss)}" rulelastupdate="2020-08-08">SSDTC={data($ssdtc)} is not before or equal to DM.DTHDTC={data($dthdtc)} for SSSTRESC='DEAD'</error>			
		
	