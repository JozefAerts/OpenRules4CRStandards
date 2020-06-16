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

(: Rule CG0318 - When PP dataset present in study then PC dataset present in study :)
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
let $definedoc := doc(concat($base,$define)) 
(: get the definition of the PP dataset :)
let $ppitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='PP']
(: and the location of the PP dataset (if any) :)
let $ppdatasetlocation := $ppitemgroupdef/def:leaf/@xlink:href
let $ppdatasetdoc := (
	if($ppdatasetlocation) then doc(concat($base,$ppdatasetlocation))
	else ()
)
(: get the definition of the PC dataset and its location :)
let $pcitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='PC']
let $pcdatasetlocation := $pcitemgroupdef/def:leaf/@xlink:href
let $pcdatasetdoc := ( 
	if($pcdatasetlocation) then doc(concat($base,$pcdatasetlocation))
	else ()
)
(: when the PP dataset exists, then also the PC dataset must exist :)
where $ppdatasetdoc and not($pcdatasetdoc)
return <error rule="CG0318" dataset="PC" rulelastupdate="2020-06-15">The PP dataset is present in the study but the PC dataset is not present in study</error>									
	
	