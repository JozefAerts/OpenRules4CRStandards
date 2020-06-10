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

(: Rule CG0143 - When DS.DSTERM indicates informed consent obtained then RFICDTC = earliest DS.DSSTDTC :)
(: This rule is a bit problematic as "when DS.TERM indicates informed consent obtained" is not clearly defined. 
The SDTM-IG states "EXAMPLES of protocol milestones: INFORMED CONSENT OBTAINED ..." :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
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
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
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
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: and the OID of DSSTDTC :)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
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
for $dmrecord in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rficdtcoid]]
    let $recnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of USUBJID and of RFICDTC :)
    let $dmusubjid := $dmrecord/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    let $rficdtc := $dmrecord/odm:ItemData[@ItemOID=$rficdtcoid]/@Value
    (: get all the DSSTDTC values in DS for this subject :)
    let $dsstdtcvalues := $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$dmusubjid]]/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
    (: and the earlies of them :)
    let $earliestdsstdtc := functx:sort($dsstdtcvalues)[1]
    (: RFICDTC = earliest DS.DSSTDTC :)
    where $rficdtc and not($rficdtc=$earliestdsstdtc)
    return <error rule="CG0143" variable="RFICDTC" dataset="DM" rulelastupdate="2017-02-18" recordnumber="{data($recnum)}">RFICDTC='{data($rficdtc)}' does not correspond to the earliest DSSDTC='{data($earliestdsstdtc)}' value</error>			
		
		