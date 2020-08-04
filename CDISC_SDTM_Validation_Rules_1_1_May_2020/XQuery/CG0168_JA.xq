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

(: Rule CG0168 - CO domain - When IDVAR != null then CODTC = null :)
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
(: get the OIDs of the CODTC and IDVAR variables :)
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
(: iterate over all CO records for which IDVAR != null :)
for $record in $codatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$idvaroid and @Value]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the IDVAR value :)
    let $idvar := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
    (: get the value of CODTC (if any) :)
    let $codtc := $record/odm:ItemData[@ItemOID=$codtcoid]/@Value
    (: When IDVAR != null then CODTC = null :)
    where $codtc  (: there IS a value for CODTC :)
    return <error rule="CG0166" dataset="CO" variable="CODTC" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">IDVAR={data($idvar)} but a value for CODTC={data($codtc)} was found</error>			
		
	