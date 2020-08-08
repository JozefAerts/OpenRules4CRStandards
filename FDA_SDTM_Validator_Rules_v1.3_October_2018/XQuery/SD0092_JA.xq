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

(: Rule SD0092 - SE - When ETCD='UNPLAN', SEUPDES may not be null
 REMARK that SEUPDES is permissible :)
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
(: get the SE dataset definition :)
let $seitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SE']
(: and the dataset location :)
let $sedatasetlocation := (
	if($defineversion = '2.1') then $seitemgroupdef/def21:leaf/@xlink:href
	else $seitemgroupdef/def:leaf/@xlink:href
)
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
(: iterate over all records where ETCD is 'UNPLAN' :)
for $record in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid]/@Value='UNPLAN']
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of SEUPDES, if any :)
    let $seupdes := $record/odm:ItemData[@ItemOID=$seupdesoid]/@Value
    (: SEUPDES must may not be null :)
    where not($seupdes)
    return <error rule="SD0092" dataset="SE" variable="ETCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Missing value for SEUPDES, when ETCD='UNPLAN'</error>			
		
	