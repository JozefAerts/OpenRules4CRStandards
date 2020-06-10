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

(: Rule CG0200 - RELREC - Within a subject each unique RELID is present on multiple RELREC records :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :) 
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the RELREC dataset definition :)
let $relrecitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='RELREC']
(: get the dataset location :)
let $relrecdatasetlocation := $relrecitemgroupdef/def:leaf/@xlink:href
let $relrecdatasetdoc := doc(concat($base,$relrecdatasetlocation))
(: get the OID of USUBJID and of RELID :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RELID']/@OID 
        where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $relidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: group all the records by USUBJID and RELID - each group should have at least 2 records :)
let $orderedrecords := (
    for $record in $relrecdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid] and odm:ItemData[@ItemOID=$relidoid]]
        group by 
        $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $c := $record/odm:ItemData[@ItemOID=$relidoid]/@Value
        return element group {  
            $record
        }
    )	
for $group in $orderedrecords
    (: each group has the same values for USUBJID and RELID :)
    (: get the USUBJID and RELID of the first record :)
    let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    let $relid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$relidoid]/@Value
    (: each group should at least have 2 records :)
    where count($group/odm:ItemGroupData) < 2
    return <error rule="CG0200" dataset="RELREC" rulelastupdate="2017-02-22" >There is only 1 record for the combination of USUBJID={data($usubjid)} and RELID={data($relid)}</error>		
		
		