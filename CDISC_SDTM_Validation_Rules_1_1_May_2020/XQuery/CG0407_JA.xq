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

(:  Rule CG0407 - EX present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the definition(s) of the EX dataset :)
let $exitemgroupdef := $definedoc//odm:ItemGroupDef[@Domain='EX' or starts-with(@Name,'EX')]
(: give an error when no EX dataset is defined at all :)
let $errormessages := (
if (not($exitemgroupdef)) then 
    <error rule="CG0407" dataset="EX" rulelastupdate="2020-08-04">No EX dataset was defined in the define.xml</error>
else (
    for $itemgroupdef in $exitemgroupdef
    let $name := $itemgroupdef/@Name
    (: get the dataset location and document :)
	let $exdatasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $exdatasetdoc := doc(concat($base,$exdatasetlocation))
    (: let $exdatasetdoc := doc(concat($base,$exdatasetlocation)) :)
    (: check whether the document exists :)
    where not($exdatasetdoc) 
    (: return <error rule="CG0407" dataset="{data($name)}" rulelastupdate="2020-08-04">Dataset {data($name)} was defined in the define.xml</error> :) 
    return <error rule="CG0407" dataset="EX" rulelastupdate="2020-08-04">The dataset {data($name)} was defined but was not found</error>
   ) 
)
return $errormessages
		
	