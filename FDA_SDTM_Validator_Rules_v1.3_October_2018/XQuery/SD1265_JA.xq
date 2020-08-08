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

(: Rule SD1265 - SUPPxx - When QORIG = 'ASSIGNED' then QEVAL != null :)
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
(: iterate over all the SUPPxx dataset definitions :)
for $suppitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $suppitemgroupdef/@Name
    (: get the dataset location :)
    let $suppdatasetlocation := (
		if($defineversion = '2.1') then $suppitemgroupdef/def21:leaf/@xlink:href
		else $suppitemgroupdef/def:leaf/@xlink:href
	)
    let $suppdatasetdoc := doc(concat($base,$suppdatasetlocation))
    (: we need the OID if QORIG and of QEVAL :)
    let $qorigoid := (
        for $a in $definedoc//odm:ItemDef[@Name='QORIG']/@OID 
        where $a = $suppitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $qevaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='QEVAL']/@OID 
        where $a = $suppitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records for which QORIG = 'ASSIGNED' :)
    for $record in $suppdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$qorigoid and @Value='ASSIGNED']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of QEVAL (if any) :)
        let $qeval := $record/odm:ItemData[@ItemOID=$qevaloid]/@Value
        (: QEVAL must != null :)
        where not($qeval)  (: QEVAL is null :)
        return <error rule="SD1265" dataset="{data($name)}" variable="QEVAL" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08" >QEVAL may not be null when QORIG='ASSIGNED'</error>			
		
	