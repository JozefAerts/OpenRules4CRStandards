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

(: Rule CG0537: DSCAT = 'DISPOSITION EVENT' and DSSCAT is NOT present in dataset, 
	then At most one record per subject per epoch :)
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
(: Iterate over all records in the DS dataset for which DSCAT='DISPOSITION EVENT',
but ONLY when DSSCAT is NOT present, 
and group them by USUBJID and EPOCH :)
let $orderedrecords := (
	for $record in $dsdoc//odm:ItemGroupData[not($dsscatoid)][odm:ItemData[@ItemOID=$dscatoid and @Value='DISPOSITION EVENT']]
	group by 
        $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $b := $record/odm:ItemData[@ItemOID=$epochoid]/@Value
        return element group {  
            $record
        }
)
(: there may be only 1 record per group :)
for $group in $orderedrecords
	where count($group/odm:ItemGroupData) > 1
	return <error rule="CG0537" dataset="DS" rulelastupdate="2020-06-21">There is more than 1 record ({count($group/odm:ItemGroupData)} records found) for the combination of USUBJID='{data($group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value)}' and EPOCH='{data($group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$epochoid]/@Value)}'</error>	
	
	