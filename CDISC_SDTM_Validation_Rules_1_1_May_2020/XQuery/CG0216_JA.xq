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

(: Rule CG0216 - SV - When SVUPDES != null then VISITDY = null
 REMARK that SVUPDES is permissible :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SV dataset definition :)
let $svitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SV']
(: and the dataset location :)
let $svdatasetlocation := (
	if($defineversion='2.1') then $svitemgroupdef/def21:leaf/@xlink:href
	else $svitemgroupdef/def:leaf/@xlink:href
)
let $svdatasetdoc := ( 
	if($svdatasetlocation) then doc(concat($base,$svdatasetlocation))
	else ()
)
(: we need the OID of VISITDY and of SEUPDES in SV :)
let $svvisitdyoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITDY']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $svupdesoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SVUPDES']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records where SVUPDES != null (i.e. not present as ItemData) :)
for $record in $svdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$svupdesoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of VISITDY (if any) :)
    let $svvisitdy := $record/odm:ItemData[@ItemOID=$svvisitdyoid]/@Value
    (: and of SVUPDES :)
    let $svupdes := $record/odm:ItemData[@ItemOID=$svupdesoid]/@Value
    (: SV.VISITDY (planned visit day) must be null :)
    where $svvisitdy
    return <error rule="CG0216" dataset="SV" variable="VISITDY" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">SV.VISITDY='{data($svvisitdy)}' is expected to be null for SVUPDES='{data($svupdes)}'</error>				
		
	