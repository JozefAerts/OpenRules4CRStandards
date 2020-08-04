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

(: Rule CG0152 - When ETCD = 'UNPLAN' then ELEMENT = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SE dataset and its location :)
let $seitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SE']
let $sedatasetlocation := (
	if($defineversion='2.1') then $seitemgroupdef/def21:leaf/@xlink:href
	else $seitemgroupdef/def:leaf/@xlink:href
)
let $sedatasetdoc := doc(concat($base,$sedatasetlocation))
(: we need the OID of ETCD and ELEMENT :)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
    where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $elementoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID 
    where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all the records in the SE dataset :)
for $record in $sedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of ETCD and of ELEMENT :)
    let $etcd := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
    let $element := $record/odm:ItemData[@ItemOID=$elementoid]/@Value
    (: When ETCD = 'UNPLAN' then ELEMENT = null :)
    where $etcd='UNPLAN' and $element  (: the latter meaning that ELEMENT is populated, so not null :)
    return <error rule="CG0152" dataset="SE" variable="ELEMENT" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Invalid value for ELEMENT={data($element)}, null was expected for ETCD='UNPLAN'</error>			
		
	