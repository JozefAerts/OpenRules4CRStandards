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

(: Rule SD1271 - The combination of ELEMENT, TESTRL TEENRL, and TEDUR must be unique for each ETCD :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the TE dataset definition and location :)
let $teitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TE']
let $tedatasetlocation := (
	if($defineversion = '2.1') then $teitemgroupdef/def21:leaf/@xlink:href
	else $teitemgroupdef/def:leaf/@xlink:href
)
let $tedatasetdoc := doc(concat($base,$tedatasetlocation))
(: we need the OIDs of ELEMENT, TESTRL, TEENRL, TEDUR and ETCD :)
let $elementoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
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
let $teduroid := (
    for $a in $definedoc//odm:ItemDef[@Name='TEDUR']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)

(: group the records by ETCD :)
let $orderedrecords := (
    for $record in $tedatasetdoc//odm:ItemGroupData
            group by 
            $b:=$record/odm:ItemData[@ItemOID=$etcdoid]/@Value
            return element group {  
                $record
            }
        
)
(: all records within a group have the same value of ETCD, 
 : so they should also have the same values of ELEMENT, TESTRL, TEENRL, and TEDUR :)
(: iterate over the groups :)
for $group in $orderedrecords
    (: take the FIRST record and get the values of ELEMENT, TESTRL, TEENRL, and TEDUR  :)
    let $element := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$elementoid]/@Value
    let $testrl := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$testrloid]/@Value
    let $teenrl := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$teenrloid]/@Value
    let $tedur := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$teduroid]/@Value
    let $recnum := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
    let $etcd := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$etcdoid]/@Value
    (: now iterate over all OTHER records and check that they do have the same values for ELEMENT, TESTRL, TEENRL, and TEDUR 
    as the first record :)
    for $record in $group/odm:ItemGroupData[position()>1]
        (: and get the value :)
        let $element2 := $record/odm:ItemData[@ItemOID=$elementoid]/@Value
        let $testrl2 := $record/odm:ItemData[@ItemOID=$testrloid]/@Value
        let $teenrl2 := $record/odm:ItemData[@ItemOID=$teenrloid]/@Value
        let $tedur2 := $record/odm:ItemData[@ItemOID=$teduroid]/@Value
        let $recnum2 := $record/@data:ItemGroupDataSeq
        (: the values for ELEMENT, TESTRL, TEENRL, and TEDUR must be the same as in the first record :)
        where (not($element=$element2) or not($testrl=$testrl2) or not($teenrl=$teenrl2) or not($tedur=$tedur2))
        return <warning rule="SD1271" dataset="TE" variable="ETCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum2)}">Records {data($recnum)} and {data($recnum2)} with ETCD='{data($etcd)}' do not have the same combination of ELEMENT, TESTRL, TEENRL, and TEDUR</warning>				
	
	