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

(: Rule CG0418 - TAETORD order of elements match order in TA within ARM of the Subject :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: Get the TA dataset :)
let $tadataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']
let $tadatasetname := $tadataset/def:leaf/@xlink:href
let $tadatasetlocation := concat($base,$tadatasetname)
(:  and the OID of TAETORD :)
let $taetordoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TAETORD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all other datasets :)
let $datasets := doc(concat($base,$define))//odm:ItemGroupDef[not(@Name='TA')]
for $dataset in $datasets
    (: get name and location :)
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: and the OID of TAETORD :)
    let $datasettaetordoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TAETORD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: now iterate over all the records that have a TAETORD :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$datasettaetordoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of TAETORD :)
        let $taetord := $record/odm:ItemData[@ItemOID=$datasettaetordoid]/@Value
        (: and check whether it can be found in the TA dataset :)
        where not((doc($tadatasetlocation))//odm:ItemGroupData/odm:ItemData[@ItemOID=$taetordoid][@Value=$taetord])
    return <error rule="CG0418" dataset="TA" variable="TAETORD" rulelastupdate="2017-03-22" recordnumer="{data($recnum)}">Invalid TAETORD in {data($name)} in dataset {data($datasetname)}. TAETORD={data($taetord)} was not found in dataset {data($tadatasetname)}</error>	
		
		