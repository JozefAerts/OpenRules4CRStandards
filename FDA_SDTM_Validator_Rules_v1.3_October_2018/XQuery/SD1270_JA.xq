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

(: Rule SD1270 - When PP dataset present in study then PC dataset present in study :)
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
(: get the definition of the PP dataset :)
let $ppitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='PP' or @Domain='PP']
(: and the location of the PP dataset (if any) :)
let $ppdatasetlocation := (
	if($defineversion = '2.1') then $ppitemgroupdef/def21:leaf/@xlink:href
	else $ppitemgroupdef/def:leaf/@xlink:href
)
let $ppdatasetdoc := doc(concat($base,$ppdatasetlocation))
(: get the definition of the PC dataset and its location :)
let $pcitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='PC' or @Domain='PC']
let $pcdatasetlocation := (
	if($defineversion = '2.1') then $pcitemgroupdef/def21:leaf/@xlink:href
	else $pcitemgroupdef/def:leaf/@xlink:href
)
let $pcdatasetdoc := doc(concat($base,$pcdatasetlocation))
(: when the PP dataset exists, then also the PC dataset must exist :)
(: where $ppdatasetdoc and not($pcdatasetdoc) :)
where doc-available($ppdatasetdoc) and not(doc-available($pcdatasetdoc))
return <error rule="SD1270" dataset="PC" rulelastupdate="2020-08-08">The PP dataset is present in the study but the PC dataset is not present in study</error>									

	