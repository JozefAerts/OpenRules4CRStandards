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

(: Rule CG0209 - SE - When ETCD != null and not last record (for the current subject) then SEENDTC != null :)
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
(: get the SE dataset definition :)
let $seitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SE']
(: and the dataset location :)
let $sedatasetlocation := $seitemgroupdef/def:leaf/@xlink:href
let $sedatasetdoc := (
	if($sedatasetlocation) then doc(concat($base,$sedatasetlocation))
	else ()
)
(: we need the OID of USUBJID, ETCD and of SESTDTC :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $seendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SEENDTC']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: group the records by USUBJID - each group contains all the records for one subject :)
let $orderedrecords := (
    for $record in $sedatasetdoc//odm:ItemGroupData
        group by 
        $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        return element group {  
            $record
        }
    )	
for $group in $orderedrecords
    (: each group has the same values for USUBJID :)
    (: count the number of records in the group :)
    let $reccount := count($group/odm:ItemGroupData)
    (: iterate over all but the last record in the group for this single subject :)
    for $record in $group/odm:ItemGroupData[position()<$reccount]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of SEENDTC and of ETCD :)
        let $seendtc := $record/odm:ItemData[@ItemOID=$seendtcoid]/@Value
        let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        (: When ETCD != null and not last record (for the current subject) then SEENDTC != null :)
        where $etcd and not($seendtc)  (: Error when ETCD is not null and SEENDTC is null  :)
        return <error rule="CG0209" dataset="SE" variable="SEENDTC" rulelastupdate="2017-02-23" recordnumber="{data($recnum)}">SEENDDTC=null for non-last record with ETCD='{data($etcd)}' </error>			
		
	