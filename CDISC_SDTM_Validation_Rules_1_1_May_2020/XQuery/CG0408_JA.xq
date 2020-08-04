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

(: Rule CG0408 - Dataset > 0 records :)
(: P.S only the datasets that are listed in the define.xml are tested :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Find all datasets :)
for $itemgroup in $definedoc//odm:ItemGroupDef
    let $datasetname := $itemgroup/@Name
	let $dataset := (
		if($defineversion='2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($dataset) then doc(concat($base,$dataset))
		else ()
	)
    (: iterate over each dataset, and count the number of records :)
    for $numrecords in count($datasetdoc//odm:ItemGroupData)
    (:  and check whether there is less than 1 record :)
    where $numrecords < 1
    return <error rule="CG0408" dataset="{data($datasetname)}" rulelastupdate="2020-08-04">{$numrecords} found in dataset: {data($datasetname)}</error>			
		
	