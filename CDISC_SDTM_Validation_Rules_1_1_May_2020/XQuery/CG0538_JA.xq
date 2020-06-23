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

(: Rule CG0538: When Subject has more than one record per Epoch with DSCAT = 'DISPOSITION EVENT', 
	then No more than 1 record per subject has DSSCAT = 'STUDY PARTICIPATION'  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the DS dataset definition :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: we need the OIDs of USUBJID, DSCAT, DSSCAT (when present) and EPOCH :)
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
let $dsscatoid := (
	for $a in $definedoc//odm:ItemDef[@Name='DSSCAT']/@OID 
	where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
	return $a
)
let $epochoid := (
	for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
	where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
	return $a
)
(: get the location of the DS dataset :)
(: and the DS document itself :)
let $dslocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdoc := (
	if($dslocation) then doc(concat($base,$dslocation))
    else ()  (: No DS dataset present :)
)
(: Group all records in the DS dataset by USUBJID and EPOCH
for which DSCAT='DISPOSITION EVENT' :)
let $orderedrecords := (
	for $record in $dsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and @Value='DISPOSITION EVENT']]
	group by 
        $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $b := $record/odm:ItemData[@ItemOID=$epochoid]/@Value
        return element group {  
            $record
        }
)
(: iterate over those groups :)
for $group in $orderedrecords
	let $numbercordsingroup := count($group/odm:ItemGroupData)
    (: in case there is more than 1 record in the group
    (with the same value for USUBJID and EPOCH), 
    there may be only 1 record for the USUBJID with DSSCAT='STUDY PARTICIPATION' :)
    (: iterate over all records in the group, 
    also when there is only one :)
    for $record in $group/odm:ItemGroupData
    	(: get the value of DSSCAT (if any) :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: for reporting, we also need the value of USUBJID and EPOCH :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $epochvalue := $record/odm:ItemData[@ItemOID=$epochoid]/@Value
        (: We need the TOTAL number of records for THIS USUBJID
        that have DSSCAT='STUDY PARTICIPATION':)
        let $countstudyparticipationrecords := count($dsdoc/odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid and @Value=$usubjidvalue]]/odm:ItemData[@ItemOID=$dsscatoid and @Value='STUDY PARTICIPATION'])
        (: Give an error when there is more than 1 'DISPOSITION EVENT' record in the group 
        (with the same value of USUBJID and EPOCH)
        AND there is more than 1 DSSCAT='STUDY PARTICIPATION' record for this subject
        :)
        where $numbercordsingroup > 1 and $countstudyparticipationrecords > 1
        return <error rule="CG0538" dataset="DS" recordnumber="{data($recnum)}" rulelastupdate="2020-06-21">There is more than 1 record ({$countstudyparticipationrecords} records were found) with DSSCAT='STUDY PARTICIPATION' although there are more than 1 records with the same value for EPOCH='{data($epochvalue)}' and DSCAT='DISPOSITION EVENT' for subject with USUBJID='{data($usubjidvalue)}'</error>	
	
	