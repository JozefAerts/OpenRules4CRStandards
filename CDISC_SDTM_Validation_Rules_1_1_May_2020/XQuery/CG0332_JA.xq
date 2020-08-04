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

(: Rule CG0332 - When dataset name length = 3 or 4 and dataset name does not begin with 'AP' or 'FA' then the first two characters of the dataset name must equal a domain that is present in the study  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all datasets definitions in the define.xml for which the name is 3 or 4 characters and does not start with 'FA' and 'AP' :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[(string-length(@Name)=3 or string-length(@Name)=4) and not(starts-with(@Name,'AP')) and not(starts-with(@Name,'FA'))]
    let $name := $itemgroupdef/@Name
    let $domain := $itemgroupdef/@domain
    (: when the domain is defined, the two first letters must be equal to the domain :)
    where $domain and not(substring($name,1,2)=$domain)
    return <error rule="CG0332" dataset="{data($name)}" rulelastupdate="2020-08-04">First two characters of dataset name '{data($name)}' does not correspond to the domain name '{data($domain)}'</error>			
		
	