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

(: Rule CG0208 - SE - When ETCD != null then SESTDTC != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
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
(: we need the OID of ETCD and of SESTDTC :)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $sestdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SESTDTC']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all record for which ETCD != null :)
for $record in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid]]  (: ETCD is populated :)
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of ETCD :)
    let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
    (: get the value of SESTDTC (if any) :)
    let $sestdtc := $record/odm:ItemData[@ItemOID=$sestdtcoid]
    (: SESTDTC may not be null :)
    where not($sestdtc)  (: SESTDTC is null :)
        return <error rule="CG0208" dataset="SE" variable="SESTDTC" rulelastupdate="2020-06-15" recordnumber="{data($recnum)}">SESTDTC may not be null for ETCD={data($etcd)}</error>			
		
	