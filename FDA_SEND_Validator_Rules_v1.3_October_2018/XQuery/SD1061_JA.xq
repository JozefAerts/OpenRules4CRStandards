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

(: ##### Not well tested yet ###### :)
(: Rule SD1061 - Missing MB dataset when MS dataset is present: Microbiology Specimen (MB) dataset should be included, when a Microbiology Susceptibility Test (MS) dataset is present :)
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
(: get the location of the MS dataset :)
let $msdatasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='MS']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='MS']/def:leaf/@xlink:href
)
let $msdatasetlocation := concat($base,$msdatasetname)
(: get the location of the MB dataset - when given anyway :)
let $mbdatasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='MB']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='MB']/def:leaf/@xlink:href
)
let $mbdatasetlocation := (
	if($mbdatasetname) then concat($base,$mbdatasetname)
	else ()
)
(: when MB is present, MS may not be absent :)
where (doc-available($msdatasetlocation) and not(doc-available($mbdatasetlocation)))
return <warning rule="SD1061" dataset="MB" rulelastupdate="2019-08-29">Document {data($mbdatasetname)} for domain MB could not be found in collection {data($base)} although document {data($msdatasetname)} is present</warning>
