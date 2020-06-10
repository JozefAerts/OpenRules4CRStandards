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

(: Rule CG0205 - SUPPxx - Suppqual dataset names <= 8 characters :)
(: Comment:
When data have been split into multiple datasets (see Section 4: 4.1.1.7, Splitting Domains), longer names such as SUPPFAMH may be needed. in cases where data about Associated Persons (see Associated Persons Implementation Guide) have been collected, an associated person with Supplemental Qualifiers for Findings About their medical history, the resulting dataset name SUPPAPFAMH) would be too long so that, in this case only, the "SUPP" portion should be shortened to "SQ". resulting in a dataset name of SQAPFAMH.
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the SUPPxx dataset definitions :)
for $suppitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP') or starts-with(@Name,'SQ')]
    let $name := $suppitemgroupdef/@Name
    (: the name may not be more than 8 characters :)
    where string-length($name) > 8
    return <error rule="CG0205" dataset="{data($name)}" rulelastupdate="2017-02-23">Supplemental Qualifier dataset name {data($name)} has more than 8 characters</error>			
		 
		