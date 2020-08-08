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
	
(: Rule SD1018 - VISITNUM/VISIT/VISITDY values do not match TV domain data:
The combination of Visit Number (VISITNUM), Visit Name (VISIT), and Planned Study Day of Visit (VISITDY) values should match entries in the Trial Visits (TV) dataset, when they are planned visits (SVUPDES = NULL)
SV dataset
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
declare function functx:is-value-in-sequence
  ($value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TV dataset :)
let $tvdataset := $definedoc//odm:ItemGroupDef[@Name='TV']
let $tvdatasetname := (
	if($defineversion = '2.1') then $tvdataset/def21:leaf/@xlink:href
	else $tvdataset/def:leaf/@xlink:href
)
let $tvdatasetlocation := concat($base,$tvdatasetname)
(: get the OID of the VISITNUM, VISIT and VISITDY in the TV daatset :)
let $tvvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a 
)
let $tvvisitoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a 
)
let $tvvisitdyoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITDY']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a 
)
(: get the SV dataset :)
let $svdataset := $definedoc//odm:ItemGroupDef[@Name='SV']
let $svdatasetname := (
	if($defineversion = '2.1') then $svdataset/def21:leaf/@xlink:href
	else $svdataset/def:leaf/@xlink:href
)
let $svdatasetlocation := concat($base,$svdatasetname)
(: get the OID of ISITNUM, VISIT and VISITDY and SVUPDES in the SV dataset
 (these may be different from within TV) :)
(: iterate over all the records in the SV dataset :)
let $svvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a 
)
let $svvisitoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a 
)
let $svvisitdyoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITDY']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a 
)
let $svupdesoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SVUPDES']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all the records in the SV dataset that have SVUPDES=null :)
for $record in doc($svdatasetlocation)//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$svupdesoid])]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the value of VISITNUM, VISIT and VISITDY :)
    let $svvisitnumvalue := $record/odm:ItemData[@ItemOID=$svvisitnumoid]/@Value
    let $svvisitvalue := $record/odm:ItemData[@ItemOID=$svvisitoid]/@Value
    let $svvisitdyvalue := $record/odm:ItemData[@ItemOID=$svvisitdyoid]/@Value
    (: now find the record in the TV dataset that has the same VISITNUM :)
    let $tvrecord := doc($tvdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tvvisitnumoid and @Value=$svvisitnumvalue]]
    (: and get the VISIT and VISITDY values :)
    let $tvvisitvalue := $tvrecord/odm:ItemData[@ItemOID=$tvvisitoid]/@Value
    let $tvvisitdyvalue := $tvrecord/odm:ItemData[@ItemOID=$tvvisitdyoid]/@Value
    (: there must be a 1:1 match :)
    where not($tvrecord) or not($svvisitvalue=$tvvisitvalue) or not($svvisitdyvalue=$tvvisitdyvalue)
    return <warning rule="SD1018" dataset="SV" variable="VISITNUM" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">VISITNUM/VISIT/VISITDY values in SV do not match TV domain data, SV VISITNUM={data($svvisitnumvalue)}, VISIT={data($svvisitvalue)}, VISITDY={data($svvisitdyvalue)}</warning>	
