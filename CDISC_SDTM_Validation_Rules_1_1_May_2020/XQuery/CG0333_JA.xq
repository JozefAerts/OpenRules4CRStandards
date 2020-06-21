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

(: Rule CG0333 - When dataset split by parent domain and dataset name length > 2 and dataset name begins with 'FA' then the characters of the dataset name after 'FA' equal a domain that present in the study :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: Iterate over all FAxx datasets :)
for $taitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'FA')]
    let $name := $taitemgroupdef/@Name
    (: get the domain about which FA is about starting from the third character :)
    let $aboutdomain := substring($name,3)
    (: there must be such a dataset/domain present :)
    where not($definedoc//odm:ItemGroupDef[@Name=$aboutdomain or @Domain=$aboutdomain]) 
    return <error rule="CDG0333" dataset="{data($name)}" rulelastupdate="2020-07-16">No corresponding dataset or domain '{data($aboutdomain)}' was found for Findings About dataset '{data($name)}'</error>			
		
	