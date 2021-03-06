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

(: Rule SD1009 - Invalid value for ETCD:
The value of Element Code (ETCD) should be no more than 8 characters in length
:)
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
(: Get the SE dataset :)
let $sedatasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='SE']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='SE']/def:leaf/@xlink:href
)
let $sedatasetdoc := ( 
	if($sedatasetname) then doc(concat($base,$sedatasetname))
	else()
)
(: also need to find out the OID of ETCD :)
let $seetcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='SE']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records in the SE dataset :)
for $record in $sedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: Get the ETCD value :)
    let $etcdvalue := $record/odm:ItemData[@ItemOID=$seetcdoid]/@Value
    (: and check whether more than 8 characters :)
    where string-length($etcdvalue) > 8
    return <warning rule="SD1009" dataset="SE" variable="ETCD" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">Invalid value for ETCD in SE dataset {data($sedatasetname)} - Value {data($etcdvalue)} has more than 8 characters</warning>
