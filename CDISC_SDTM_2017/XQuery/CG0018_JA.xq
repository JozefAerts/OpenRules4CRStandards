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

(: Rule CG0018 - Precondition: Supplemental Qualifier dataset
Rule: Split dataset names length <= 8 :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all datasets in the define.xml that have are SUPPxx (Supplemental Qualifiers) datasets :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    (: get the domain name - value of the 'Domain' attribute :)
    let $domain := $itemgroup/@Domain
    (: and the dataset name (@Name attribute) :)
    let $name := $itemgroup/@Name
    (: and get the filename :)
    let $filename := $itemgroup/def:leaf/@xlink:href
    (: the prefix (part before the dot) MUST have NOT MORE than eight characters (e.g. supplb.xpt) :)
    let $numcharsfilename := string-length(substring-before($filename,'.'))
    let $numcharsdatasetname := string-length($name)
    where ($numcharsfilename > 8 or $numcharsdatasetname > 8)
        return <error rule="CG0018" dataset="{data($name)}" rulelastupdate="2017-02-04">Supplemental Qualifier dataset {data($name)} has a dataset/file name '{data($filename)}' with more than 8 characters</error>		
	