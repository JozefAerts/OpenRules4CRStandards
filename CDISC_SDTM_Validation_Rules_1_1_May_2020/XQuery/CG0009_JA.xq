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

(: Rule CDG0009 - EPOCH in TA.EPOCH
Precondition: none
Rule: EPOCH in TA.EPOCH
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
(: Get the TA dataset :)
let $tadataset := $definedoc//odm:ItemGroupDef[@Name='TA']
let $tadatasetname := (
	if($defineversion='2.1') then $tadataset/def21:leaf/@xlink:href
	else $tadataset/def:leaf/@xlink:href
)
let $tadatasetlocation := concat($base,$tadatasetname)
(: and get the OID of the EPOCH variable :)
let $taepochoid := (
    for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
    return $a
)
(: now iterate over all other datasets :)
let $datasets := $definedoc//odm:ItemGroupDef[not(@Name='TA')]
for $dataset in $datasets
    (: get name and location :)
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
    (: and the OID of EPOCH :)
    let $datasetepochoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in this dataset that have a EPOCH variable :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$datasetepochoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: now get the value of the EPOCH variable :)
        let $epochvalue := $record/odm:ItemData[@ItemOID=$datasetepochoid]/@Value
        (: and check whether it is present in the TA dataset :)
        where not(doc($tadatasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$taepochoid][@Value=$epochvalue])
        return <error rule="CG0009" dataset="{data($name)}" variable="EPOCH" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Value for EPOCH={data($epochvalue)} in dataset {data($datasetname)} was not found in the TA dataset {data($tadatasetname)}</error>	
