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

(: Rule SD1262: When SSSTRESC = 'DEAD' then SSDTC >= DS.DSSTDTC :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: sorting function - also sorts dates :)
declare function functx:sort
  ( $seq as item()* )  as item()* {

   for $item in $seq
   order by $item
   return $item
 } ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the DS dataset :)
let $dsdatasetlocation := (
	if($defineversion = '2.1') then $dsitemgroupdef/def21:leaf/@xlink:href
	else $dsitemgroupdef/def:leaf/@xlink:href
)
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Get the SS (Subject Status) dataset and its location :)
let $ssitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SS']
let $ssdatasetlocation := (
	if($defineversion = '2.1') then $ssitemgroupdef/def21:leaf/@xlink:href
	else $ssitemgroupdef/def:leaf/@xlink:href
)
let $ssdatasetdoc := doc(concat($base,$ssdatasetlocation))
(: we need the OID of DSSTDTC and of USUBJID in DS :)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
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
    (: get all the DSSTDTC values for this subject :)
    let $dsstdtcvalues := $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$ssusubjid]]/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
    (: sort the DSSTDTC values and take the latest one :)
    let $latestdsstdtc := functx:sort($dsstdtcvalues)[last()]
    (: SSDTC >= DS.DSSTDTC :)
    where $ssdtc castable as xs:date and $latestdsstdtc castable as xs:date and not(xs:date($ssdtc) >= xs:date($latestdsstdtc))
    return <error rule="SD1262" variable="SSDTC" dataset="SS" recordnumber="{data($recnumss)}" rulelastupdate="2020-08-08">SSDTC={data($ssdtc)} is not before or equal to latest DSSTDTC={data($ssdtc)} for SSSTRESC='DEAD'</error>			
		
	