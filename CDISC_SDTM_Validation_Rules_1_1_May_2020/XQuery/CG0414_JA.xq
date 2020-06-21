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

(: Rule CG0414 - When ETCD != 'UNPLAN' in SE,TA then ETCD = TE.ETCD :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TE (Trial Elements) dataset :)
let $teitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TE']
let $tedatasetlocation := $teitemgroupdef/def:leaf/@xlink:href
let $tedatasetdoc := doc(concat($base,$tedatasetlocation))
(: get the OID of ETCD in TE :)
let $teetcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over the SE and TA dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='SE' or @Name='TA']
    let $name := $itemgroupdef/@Name
    (: get the OID of ETCD in SE or TA :)
    let $etcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid and @Value!='UNPLAN']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ETCD :)
        let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        (: and check whether there is such a value in TE :)
        let $teetcdcount := count($tedatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$teetcdoid and @Value=$etcd])
        where $teetcdcount = 0
        return <error rule="CG0414" dataset="{data($name)}" rulelastupdate="2017-03-22" recordnumber="{data($recnum)}">ETCD value='{data($etcd)}' was not found in TE</error>											
		
	