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

(: Rule CG0218 - SV - When EPOCH present in dataset and SESTDTC <= SVSTDTC and SVSTDTC <= SEENDTC then SV.EPOCH = SE.EPOCH :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SV dataset definition :)
let $svitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SV']
(: and the dataset location :)
let $svdatasetlocation := $svitemgroupdef/def:leaf/@xlink:href
let $svdatasetdoc := doc(concat($base,$svdatasetlocation))
(: we need the OID of EPOCH and of SVSTDTC in SV :)
let $svepochoid := (
    for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $svstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SVSTDTC']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: and we need the OID of USUBJID in SV :)
let $svusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the SE dataset definition :)
let $seitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SE']
(: and the dataset location :)
let $sedatasetlocation := $seitemgroupdef/def:leaf/@xlink:href
let $sedatasetdoc := doc(concat($base,$sedatasetlocation))
(: we need the oid of SESTDTC, SEENDTC and of EPOCH in SE :)
let $sestdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SESTDTC']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $seendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SEENDTC']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $seepochoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TAETORD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: and we need the OID of USUBJID in SE :)
let $seusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the record for which EPOCH is present in SV :)
for $record in $svdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$svepochoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of EPOCH and SVSTDTC :)
    let $svepoch := $record/odm:ItemData[@ItemOID=$svepochoid]/@Value
    let $svstdtc := $record/odm:ItemData[@ItemOID=$svstdtcoid]/@Value
    let $svusubjid := $record/odm:ItemData[@ItemOID=$svusubjidoid]/@Value
    (: look up SVSTDTC in SE - SVSTDTC must be between SESTDTC and SEENDTC for this subject :)
    for $serecord in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$seusubjidoid and @Value=$svusubjid]][odm:ItemData[@ItemOID=$sestdtcoid] and odm:ItemData[@ItemOID=$seendtcoid]]
        (: get the values of SESTDTC and SEENDTC :)
        let $sestdtc := $serecord/odm:ItemData[@ItemOID=$sestdtcoid]/@Value
        let $seendtc := $serecord/odm:ItemData[@ItemOID=$seendtcoid]/@Value
        (: and the value of EPOCH in SE  :)
        let $seepoch := $serecord/odm:ItemData[@ItemOID=$seepochoid]/@Value
        (: when SESTDTC <= SVSTDTC and SVSTDTC <= SEENDTC then TAETORD = SE.TAETORD
        then SV.EPOCH must be = SE.EPOCH:)
        where $sestdtc castable as xs:date and $seendtc castable as xs:date and $svstdtc castable as xs:date 
        and xs:date($sestdtc) <= xs:date($svstdtc) and xs:date($svstdtc) <= xs:date($seendtc)
        and not($svepoch=$seepoch)
        return <error rule="CG0218" dataset="SV" variable="EPOCH" rulelastupdate="2017-02-24" recordnumber="{data($recnum)}">TAETORD is present in SV dataset and SESTDTC &lt;= SVSTDTC and SVSTDTC &lt;= SEENDTC, but SV.EPOCH={data($svepoch)} is not equal to SE.EPOCH={data($seepoch)}</error>		
		
		