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

(: Rule SD0067 - Invalid ETCD:
Element Code (ETCD) values should match entries in the Trial Elements (TE) dataset, except for unplanned Element (ETCD = 'UNPLAN')
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TA and SE datasets :)
let $datasets := $definedoc//odm:ItemGroupDef[@Name='TA' or @Name='SE']
(: Get the TE dataset :)
let $tedatasetlocation := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='TE']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='TE']/def:leaf/@xlink:href
)
(: and the OID for ETCD in the TE dataset :)
let $teectdoid := (
	for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
    return $a
)  
(: iterate over the two datasets :)
for $dataset in $datasets
    let $datasetname := $dataset/@Name
	let $datasetlocation := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
	let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation)) 
		else ()
	)
    (: Get the OID for ETCD :)
    let $etcdoid := (
		for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
		where $a = $definedoc//odm:ItemGroupDef[@Name=$datasetname]/odm:ItemRef/@ItemOID
		return $a
	)
    (: now iterate over all records within the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: exclude the one for which the ETCD value is 'UNPLAN' :)
        let $etcdvalue := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        (: and check whether present in the TE dataset, excluding the 'UNPLAN' ones :)
        where not(doc(concat($base,$tedatasetlocation))//odm:ItemGroupData/odm:ItemData[@ItemOID=$teectdoid][@Value=$etcdvalue]) and not($etcdvalue='UNPLAN')
        return <error rule="SD0067" rulelastupdate="2019-09-03" dataset="SE" variable="ETCD" recordnumber="{data($recnum)}">Invalid ETCD: Element Code ETCD={data($etcdvalue)} in dataset {data($datasetlocation)} was not found in TE dataset {data($tedatasetlocation)}</error>
