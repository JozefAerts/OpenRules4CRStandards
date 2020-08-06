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

(: Rule SD1065 - CO domain - When IDVARVAL != null then RDOMAIN != null :)
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
(: let $base := '/db/fda_submissions/SEND_Nimble/' :)
(: let $define := 'define_DSXML.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the CO dataset :)
let $coitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='CO']
let $codatasetlocation := (
	if($defineversion='2.1') then $coitemgroupdef/def21:leaf/@xlink:href
	else $coitemgroupdef/def:leaf/@xlink:href
)
let $codatasetdoc := (
	if($codatasetlocation) then doc(concat($base,$codatasetlocation))
	else ()
)
(: get the OIDs of the RDOMAIN and IDVARVAL variables :)
let $rdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $idvarvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all CO records for which there IS a IDVARVAL data point :)
for $record in $codatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$idvarvaloid and @Value]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the IDVARVAL value :)
    let $idvarval := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
    (: get the value of RDOMAIN (if any) :)
    let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
    (: When IDVARVAL != null then RDOMAIN != null :)
    where not($rdomain)  (: there is no value for RDOMAIN :)
    return <error rule="SD1065" dataset="CO" variable="RDOMAIN" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">IDVARVAL={data($idvarval)} but RDOMAIN=null</error>			
		
	