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

(: Rule CG0535: When Subject has more than one record per Epoch with DSCAT = 'DISPOSITION EVENT', 
then DSSCAT must be present/populated  :)
(: P.S. Rule says "present", but this doesn't make sense ... 
It very probably should say "present and != null) :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
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
let $dslocation := (
	if($defineversion='2.1') then $dsitemgroupdef/def21:leaf/@xlink:href
	else $dsitemgroupdef/def:leaf/@xlink:href
)
let $dsdoc := (
	if($dslocation) then doc(concat($base,$dslocation))
    else ()  (: No DS dataset present :)
)
(: Group all records in the DS dataset that have DSCAT='DISPOSITION EVENT' by USUBJID and EPOCH :)
let $orderedrecords := (
	for $record in $dsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and @Value='DISPOSITION EVENT']]
	group by 
        $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $b := $record/odm:ItemData[@ItemOID=$epochoid]/@Value
        return element group {  
            $record
        }
)
(: iterate over these groups :)
for $group in $orderedrecords
	let $numercordsingroup := count($group/odm:ItemGroupData)
    (: in case there is more than 1 record in the group
    (with the same value for USUBJID and EPOCH), 
    then DSSCAT must be present and populated :)
    (: iterate over all records in the group, 
    also when there is only one :)
    for $record in $group/odm:ItemGroupData
    	(: get the value of DSSCAT (if any) :)
        let $recnum := $record/@data:ItemGroupDataSeq
        let $dsscatvalue := $record/odm:ItemGroupData/odm:ItemData[@ItemOID=$dsscatoid]
        (: for reporting, we also need the value of USUBJID and EPOCH :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $epochvalue := $record/odm:ItemData[@ItemOID=$epochoid]/@Value
        (: Give an error when the number of records in the group 
        (with the same value for USUBJID and EPOCH) is >1, 
        and DSSCAT is absent or not populated :)
        where $epochvalue and $numercordsingroup > 1 and not($dsscatvalue)
        return <error rule="CG0535" dataset="DS" variable="DSSCAT" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">DSSCAT is not populated although there are {data($numercordsingroup)} records with the same value of USUBJID = '{data($usubjidvalue)}' and EPOCH='{data($epochvalue)}' and DSCAT='DISPOSITION EVENT'</error> 
	
	