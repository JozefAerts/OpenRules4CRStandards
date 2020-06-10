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

(: Rule CG0310 - Variable name length <= 8 :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all datasets definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: iterate over all variable OIDs :)
    for $itemoid in $itemgroupdef/odm:ItemRef/@ItemOID
    (: get the Name of the variable :)
    let $varname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
    (: the length of the variable may not be more than 8 characters :)
    where string-length($varname) > 8
    return <error rule="CG0310" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2018-08-12">The variable name '{data($varname)}' has more than 8 characters</error>							
		
		