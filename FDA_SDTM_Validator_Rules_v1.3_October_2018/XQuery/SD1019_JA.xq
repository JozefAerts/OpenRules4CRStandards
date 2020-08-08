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

(: Rule SD1019 - VISITDY is populated for unplanned visit:
Planned Study Day of Visit (VISITDY) should equal NULL for unplanned visits, where Description of Unplanned Visit (SVUPDES) is populated
SV dataset
:)
(: TODO: testing - we did not have a good testing dataset :)
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
(: get the SV dataset :)
let $svdataset := $definedoc//odm:ItemGroupDef[@Name='SV']
let $svdatasetname := (
	if($defineversion = '2.1') then $svdataset/def21:leaf/@xlink:href
	else $svdataset/def:leaf/@xlink:href
)
let $svdatasetlocation := concat($base,$svdatasetname)
(: and get the OID of the VISITDY and SVUPDES variables :)
let $visitdyoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITDY']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a  
)
let $svsupdesoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SVUPDES']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all records in the SV dataset that have SVUPDES populated :)
for $record in doc($svdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$svsupdesoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the value of VISITDY - if any :)
    let $visitdyvalue := $record/odm:ItemData[@ItemOID=$visitdyoid]/@Value
    (: VISITDY must be null :)
    return <warning rule="SD1019" dataset="SV" variable="VISITDY" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">VISITDY is populated for unplanned visit, value for VISITDY={data($visitdyvalue)} in dataset SE</warning>	
