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

(: Rule SD1027 - ELEMENT present in dataset and ETCD present in dataset then ELEMENT and ETCD have a one-to-one relationship
Applicable to SE, TA, TE :)
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
(: Get the SE, TA and TE datasets:)
let $datasets := doc(concat($base,$define))//odm:ItemGroupDef[@Name='SE' or @Name='TA' or @Name='TE']
(: and iterate over these :)
for $datasetdef in $datasets
    (: get the dataset name and location :)
    let $name := $datasetdef/@Name
	let $datasetname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: get the OIDs of ETCD and ELEMENT :)
    let $etcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a 
    )
    let $elementoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID 
        where $a =$datasetdef/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all records that have BOTH ETCD and ELEMENT populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid] and odm:ItemData[@ItemOID=$elementoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values of ETCD and ELEMENT :)
        let $etcdvalue := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        let $elementvalue := $record/odm:ItemData[@ItemOID=$elementoid]/@Value
        (: iterate over all further records that DO have ETCD and ELEMENT populated AND for which ETCD corresponds to the current value of ETCD :)
        for $record2 in $datasetdoc//odm:ItemGroupData[@data:ItemGroupDataSeq > $recnum][odm:ItemData[@ItemOID=$etcdoid] and odm:ItemData[@ItemOID=$elementoid] and odm:ItemData[@ItemOID=$etcdoid]/@Value=$etcdvalue]
            let $recnum2 := $record2/@data:ItemGroupDataSeq
            (: and again, get the values of ETCD and ELEMENT :)
            let $etcdvalue2 := $record2/odm:ItemData[@ItemOID=$etcdoid]/@Value (: should be identical to $etcdvalue :)
            let $elementvalue2 := $record2/odm:ItemData[@ItemOID=$elementoid]/@Value
            (: ELEMENT must be equal to ELEMENT of the the earlier record :)
            where not($elementvalue=$elementvalue2)
            return <error rule="SD1027" dataset="{data($name)}" variable="ETCD" rulelastupdate="2019-08-27" recordnumber="{data($recnum2)}">Non-unique combination for ELEMENT and ETCD. Record {data($recnum)} has ETCD='{data($etcdvalue)}' and and ELEMENT='{data($elementvalue)}' whereas record {data($recnum2)} has ETCD='{data($etcdvalue2)}' and has ELEMENT='{data($elementvalue2)}' in dataset {data($name)}</error>			
		
	