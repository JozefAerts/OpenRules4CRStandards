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

(: Rule CG0325 - The combination of TESTRL and TEENRL is unique for each ETCD  :)
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
(: get the TE dataset definition and location :)
let $teitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TE']
let $tedatasetlocation := $teitemgroupdef/def:leaf/@xlink:href
let $tedatasetdoc := doc(concat($base,$tedatasetlocation))
(: we need the OIDs of TESTRL, TEENRL and ETCD :)
let $testrloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TESTRL']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $teenrloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TEENRL']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records, get the values of TESTRL and TEENRL and check whether the same combination
occurs in subsequent records :)
(: ALTERNATIVE (not done here): group the records by TESTRL and TEENRL and check whether each group only contains one record :)
for $record in $tedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of TESTRL and TEENRL :)
    let $testrl := $record/odm:ItemData[@ItemOID=$testrloid]/@Value
    let $teenrl := $record/odm:ItemData[@ItemOID=$teenrloid]/@Value
    (: and of ETCD :)
    let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
    (: look in subsequent records with same values for TESTRL and TEENRL :)
    for $record2 in $record/following-sibling::odm:ItemGroupData[odm:ItemData[@ItemOID=$testrloid and @Value=$testrl]][odm:ItemData[@ItemOID=$teenrloid and @Value=$teenrl]]
        let $recnum2 := $record2/@data:ItemGroupDataSeq
        let $etcd2 := $record2/odm:ItemData[@ItemOID=$etcdoid]/@Value
        (: as both records have the same value for TESTRL and TEENRL, give an error :)
        return <error rule="CG0325" dataset="TE" recordnumber="{data($recnum2)}" rulelastupdate="2020-06-16">Record {data($recnum2)} with ETCD='{data($etcd2)}' has the same combination of values of  TESTRL='{data($testrl)}' and TEENRL='{data($teenrl)}' as record {data($recnum)} with ETCD='{data($etcd)}'</error>											
		
	