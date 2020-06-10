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

(: Rule CG0398 - When DSCAT = 'DISPOSITION EVENT' and DSTERM != 'COMPLETED' then at most one record per subject per epoch :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the DS dataset definition :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
    (: we need the OIDs of USUBJID, DSCAT, DSTERM and EPOCH :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $dscatoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSCAT']/@OID 
        where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $dstermoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSTERM']/@OID 
        where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $epochoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
        where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and the document :)
    let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
    let $dsdatsetdoc := doc(concat($base,$dsdatasetlocation))
    (: get (filter) all records for which 'DISPOSITION EVENT' and DSTERM != 'COMPLETED' :)
    let $completedrecords := $dsdatsetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and @Value='DISPOSITION EVENT'] and odm:ItemData[@ItemOID=$dstermoid and @Value='COMPLETED']]
    (: group the records by EPOCH and USUBJID - each group should contain no more than 1 records :)
    let $orderedrecords := (
        for $record in $completedrecords
            group by 
            $b := $record/odm:ItemData[@ItemOID=$epochoid]/@Value,
            $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
            return element group {  
                $record
            }
        )
    (: each group should contain no more than 1 records :)
    for $group in $orderedrecords
        let $count := count($group/odm:ItemGroupData)
        (: get record number of 'last' record in group  - for reporting:)
        let $recnum := $group/odm:ItemGroupData[last()]/@data:ItemGroupDataSeq
        (: get the value of USUBJID and of EPOCH for reporting  :)
        let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $epoch := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$epochoid]/@Value
        where $count > 1
        return <error rule="CG0398" dataset="DS" recordnumber="{data($recnum)}" rulelastupdate="2017-03-17">For DSCAT = 'DISPOSITION EVENT' and DSTERM = 'COMPLETED', {data($count)} records were found for USUBJID='{data($usubjid)}' and EPOCH='{data($epoch)}'. Only 1 record is allowed.</error>						
		
		