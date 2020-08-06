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

(: Rule SD0087 - When Milestone associated with RFSTDTC is start of treatment and ACTARM not in ('Screen Failure' 'Not Assigned' 'Not Treated') then RFSTDTC != null  :)
(: We can only check that when ACTARM not in ('Screen Failure' 'Not Assigned' 'Not  Treated') then RFSTDTC != null :)
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
(: get the OID of ACTARM and of RFSTDTC :)
let $actarmoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ACTARM']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over the records in DM :)
for $record in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of ACTARM and of RFSTDTC :)
    let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
    let $rfstdtcvalue := $record/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
    (: when ACTARM not in ('Screen Failure', 'Not Assigned') then RFSTDTC != null :)
    where not($actarmvalue='Screen Failure' or $actarmvalue='Not Assigned') and not($rfstdtcvalue)
    return <error rule="SD0087" variable="RFSTDTC" dataset="DM" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">RFSTDTC expected to be not null for ACTARM='{data($actarmvalue)}'</error>			
		
	