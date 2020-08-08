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

(: Rule SD1240 - All subjects must have an Informed Consent record in the Disposition domain :)
(: This rule is a bit problematic as "when DS.TERM indicates informed consent obtained" is not clearly defined. 
The SDTM-IG states "EXAMPLES of protocol milestones: INFORMED CONSENT OBTAINED ..." :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' 
let $define := 'define_2_0.xml'  :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := (
	if($defineversion = '2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of RFICDTC in DM :)
let $rficdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFICDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: we also need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: get the DS dataset and its location :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
let $dsdatasetlocation := (
	if($defineversion = '2.1') then $dsitemgroupdef/def21:leaf/@xlink:href
	else $dsitemgroupdef/def:leaf/@xlink:href
)
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: and the OID of DSSTDTC and of DSTERM :)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $dstermoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSTERM']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: we also need the OID of USUBJID in DS :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all the records in DM that have a value for RFICDTC :)
(: for $dmrecord in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rficdtcoid]] :)
(: 2020-08-08; we iterate over ALL records in DM, not only over these for which there is an RFICDTSC record :)
for $dmrecord in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of USUBJID :)
    let $dmusubjid := $dmrecord/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    (: let $rficdtc := $dmrecord/odm:ItemData[@ItemOID=$rficdtcoid]/@Value :)
    (: get all records in DS for this subject which have DSTERM='INFORMED CONSENT OBTAINED' :)
    let $dsinfconsents := $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$dmusubjid]]/odm:ItemData[@ItemOID=$dstermoid and @Value='INFORMED CONSENT OBTAINED']
    (: there must be at least one such record :)
    where count($dsinfconsents) = 0
    return <warning rule="SD1240" variable="DM" dataset="DM" rulelastupdate="2020-08-08" recordnumber="{$recnum}">No informed consent record (DSTERM='INFORMED CONSENT OBTAINED') in DS could be found for subject {data($dmusubjid)}</warning>			
	
	