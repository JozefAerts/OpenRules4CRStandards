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

(: Rule CG0211 - SE - When SEUPDES != null then ETCD = 'UNPLAN'
 REMARK that SEUPDES is permissible :)
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
let $sedatasetdoc := doc(concat($base,$sedatasetlocation))
(: we need the OID of ETCD and of SEUPDES :)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $seupdesoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SEUPDES']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records where SEUPDES is not null (i.e. present as ItemData) :)
for $record in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$seupdesoid]/@Value]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of ETCD and of SEUPDES :)
    let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
    let $seupdes := $record/odm:ItemData[@ItemOID=$seupdesoid]/@Value
    (: ETCD must be 'UNPLAN' :)
    where not($etcd='UNPLAN')
    return <error rule="CG0211" dataset="SE" variable="ETCD" rulelastupdate="2017-02-23" recordnumber="{data($recnum)}">When SEUPDES!=null then ETCD is expected to be 'UNPLAN'. ETCD='{data($etcd)}', SEUPDES='{data($seupdes)}' was found</error>				
		
		