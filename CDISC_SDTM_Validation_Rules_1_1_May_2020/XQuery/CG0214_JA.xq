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

(: Rule CG0214 - SV - When SVUPDES != null then VISITNUM not in TV.VISITNUM
 REMARK that SVUPDES is permissible :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
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
(: we need the OID of VISITNUM and of SVUPDES in SV :)
let $svvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $svupdesoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SVUPDES']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: we also need the TV dataset :)
let $tvitemgroupdef := $definedoc//odm:ItemGroupDef[@OID='TV']
let $tvdatsetlocation := (
	if($defineversion='2.1') then $tvitemgroupdef/def21:leaf/@xlink:href
	else $tvitemgroupdef/def:leaf/@xlink:href
)
let $tvdatasetdoc := (
	if($tvdatsetlocation) then doc(concat($base,$tvdatsetlocation))
	else ()
)
(: and the OID of visitnum in TV :)
let $tvvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $tvitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get all the values of VISITNUM in TV (as a sequence/array) :)
let $tvvisitnums := $tvdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tvvisitnumoid]/@Value
(: iterate over all records where SVUPDES != null (i.e. present as ItemData) :)
for $record in $svdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$svupdesoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of SVUPDES and of VISITNUM :)
    let $svupdes := $record/odm:ItemData[@ItemOID=$svupdesoid]/@Value
    let $svvisitnum := $record/odm:ItemData[@ItemOID=$svvisitnumoid]/@Value
    (: SV.VISITNUM may not be one of TV.VISITNUM :)
    where functx:is-value-in-sequence($svvisitnum,$tvvisitnums)
    return <error rule="CG0214" dataset="SV" variable="VISITNUM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">SVUPDES={data($svupdes)} but SV.VISITNUM={data($svvisitnum)} was found in TV</error>			
		
	