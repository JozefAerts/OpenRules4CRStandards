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

(: Rule CG0413 - Dataset name begins with DOMAIN value  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: for each dataset, WHEN @Domain is present on ItemGroupDef (only required in the context of a regulatory submission) 
AND the dataset is NOT a SUPPQUAL dataset, we will check: 
a) whether the Name attribute (dataset name) starts with the domain name (case sensitive) 
b) whether the dataset name (the file name) starts with the domain name (case-insensitive) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[not(starts-with(@Name,'SUPP'))]
    let $domain := $itemgroupdef/@Domain
    let $name := $itemgroupdef/@Name
    let $datasetfilename := $itemgroupdef/def:leaf/@xlink:href   (: This assumes that the file is in the same directory as the define.xml  :)
    let $datasetfilenameuppercase := upper-case($datasetfilename)
    (: dataset name and file name must start with the domain name :)
    where $domain != '' and (not(starts-with($name,$domain)) or not(starts-with($datasetfilenameuppercase,$domain)))
    return <error rule="CG0413" dataset="{data($name)}" rulelastupdate="2020-06-18" >Dataset name='{data($name)}' or file name='{data($datasetfilename)}' does not start with the domain name='{data($domain)}'</error>						
		
	