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

(: Rule SD1008 - CODTC must be NULL when RDOMAIN, IDVAR and IDVARVAL are populated :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;  
declare variable $define external; 
let $definedoc := doc(concat($base,$define))
(: get the CO dataset :)
let $coitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='CO' or @Domain='CO']
let $codatasetlocation := $coitemgroupdef/def:leaf/@xlink:href
let $codatasetdoc := doc(concat($base,$codatasetlocation))
(: get the OIDs of the CODTC, IDVAR, IDVARVAL and RDOMAIN variables :)
let $codtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='CODTC']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $idvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $idvarvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $rdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all CO records for which IDVAR != null, IDVARVAL != null and RDOMAIN != null :)
for $record in $codatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$idvaroid and @Value] and odm:ItemData[@ItemOID=$idvarvaloid and @Value] and odm:ItemData[@ItemOID=$rdomainoid and @Value]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the IDVAR value :)
    let $idvar := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
    (: get the value of CODTC (if any) :)
    let $codtc := $record/odm:ItemData[@ItemOID=$codtcoid]/@Value
    (: When IDVAR != null then CODTC = null :)
    where $codtc  (: there IS a value for CODTC :)
    return <warning rule="SD1008" dataset="CO" variable="CODTC" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">IDVAR={data($idvar)} but a value for CODTC={data($codtc)} was found</warning>					
	
	