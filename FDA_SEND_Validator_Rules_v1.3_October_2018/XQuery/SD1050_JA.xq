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

(: Rule SD1050: Non-unique value for ETCD within ELEMENT :)
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
(: Iterate over the SE and TA datasets :)
for $dataset in  $definedoc//odm:ItemGroupDef[@Name='SE' or @Name='TA']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and get the OID of ETCD and ELEMENT :)
    let $etcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $elementoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: group by ELEMENT - each group has the same valueELEMENT :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$elementoid]/@Value
            return element group {  
                $record
            }
    )
    (: iterate over the groups, get the first record only to indentify ETCD and ELEMENT :)
    for $group in $orderedrecords
        let $etcdvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$etcdoid]/@Value
        let $elementvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$elementoid]/@Value
        let $recnum := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        (: now check whether there are any other records that have a different value for ETCD :)
        for $record in $group/odm:ItemGroupData[position()>1]
            let $etcdvalue2 := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
            (: if the ETCD value is different from that within the first record of the group, give an error :)
            let $recnum2 := $record/@data:ItemGroupDataSeq
            where $etcdvalue != $etcdvalue2
            return <error rule="SD1050" dataset="{data($name)}" variable="ETCD" recordnumber="{data($recnum2)}" rulelastupdate="2019-08-14">Non-unique value for ETCD within ELEMENT '{data($elementvalue)}' in dataset {data($datasetname)}. Record {data($recnum2)} has ETCD value '{data($etcdvalue2)}' whereas record {data($recnum)} has ETCD value '{data($etcdvalue)}'</error>

