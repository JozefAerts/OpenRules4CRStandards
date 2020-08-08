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

(: Rule SD1012 - Invalid ETCD/ELEMENT:
The combination of Element Code (ETCD) and Description of Element (ELEMENT) values should match entries in the Trial Elements (TE) dataset, except for unplanned Element (ETCD = 'UNPLAN') - dataset SE,TA :)
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
(: Get the TE dataset :)
let $tedatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='TE']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='TE']/def:leaf/@xlink:href
)
let $tedatasetlocation := concat($base,$tedatasetname)
(: Get the OID of ETCD and ELEMENT in the TE dataset :)
let $teetcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
    return $a
)
let $teelementoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
    return $a
)
(: Get the TA and SE datasets :)
let $datasets := $definedoc//odm:ItemGroupDef[@Name='TA' or @Name='SE']
(: iterate over these datasets :)
for $dataset in $datasets
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the ETCD and ELEMENT variables in the TA or SE datasets :)
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
    (: iterate over all the records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value for ETCD and ELEMENT :)
        let $etcdvalue := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        let $elementvalue := $record/odm:ItemData[@ItemOID=$elementoid]/@Value
        (: and find a record in the TE dataset - exclude however ETCD='UNPLAN' :)
        where not(doc($tedatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$teetcdoid][@Value=$etcdvalue] and odm:ItemData[@ItemOID=$teelementoid][@Value=$elementvalue]]) and not($etcdvalue='UNPLAN')
        return <error rule="SD1012" dataset="{data($name)}" variable="ETCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid ETCD/ELEMENT in dataset {data($datasetname)}. The combination of Element Code ETCD={data($etcdvalue)} and Description of Element ELEMENT={data($elementvalue)} was not found in the TE dataset {data($tedatasetname)}</error>
