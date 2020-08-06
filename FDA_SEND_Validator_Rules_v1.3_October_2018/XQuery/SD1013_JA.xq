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

(: Rule SD1013 - TAETORD is populated, ETCD = 'UNPLAN':
Planned Order of Elements within Arm (TAETORD) should be NULL, when subject's experience for a particular period of time is represented as an unplanned Element (ETCD = 'UNPLAN')
SE dataset :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SE dataset :)
let $sedataset := $definedoc//odm:ItemGroupDef[@Name='SE']
let $sedatasetname := (
	if($defineversion='2.1') then $sedataset/def21:leaf/@xlink:href
	else $sedataset/def:leaf/@xlink:href
)
let $sedatasetdoc := (
	if($sedatasetname) then doc(concat($base,sedatasetname))
	else ()
)
(: and get the OID of the TAETORD and ETCD variables :)
let $taetordoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TAETORD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SE']/odm:ItemRef/@ItemOID
    return $a    
)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SE']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in the SE dataset that have ETCD=UNPLAN :)
for $record in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid and @Value='UNPLAN']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the value of TAETORD - if any :)
    let $taetordvalue := $record/odm:ItemData[@ItemOID=$taetordoid]/@Value
    (: TAETORD must be null :)
    where string-length($taetordvalue) > 0
    return <warning rule="SD1013" dataset="SE" variable="TAETORD" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">TAETORD is populated, value={data($taetordvalue)} with ETCD='UNPLAN' in dataset SE</warning>
