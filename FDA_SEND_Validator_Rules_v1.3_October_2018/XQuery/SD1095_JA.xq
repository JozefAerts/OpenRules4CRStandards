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

(: Rule SD1095 - Split datasets must not have name of original domain. 
E.g., lbhm.xpt is a valid name, when lb.xpt is not a valid dataset name for split domain.
:)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets in the define.xml that have a 'Domain' attribute (this should be all of them)
and within INTERVENTIONS, FINDINGS, EVENTS :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Domain][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='FINDINGS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    (: get the domain name - value of the 'Domain' attribute :)
    let $domain := $itemgroup/@Domain
    (: and the dataset name (@Name attribute) :)
    let $name := $itemgroup/@Name
    (: and get the filename :)
	let $filename := (
		if($defineversion='2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    (: get the position of the current ItemGroupDef in the series :)
    let $pos := $itemgroup/position()
    (: get all the ItemGroupDefs with the same value for the 'Domain' attribute
    If so, this means that the dataset is a 'splitted' dataset. 
    P.S. There currently is no other way to find out :)
    let $count := count($definedoc//odm:ItemGroupDef[@Domain=$domain])
    (: in case there is more than one such dataset, the prefix (part before the dot)
    MUST have MORE than two characters (e.g. qscs.xpt) :)
    where $count > 1 and not(string-length(substring-before($filename,'.')) > 2)
        (: filenames should have >2 characters before the dot :)
        return <error rule="SD1095" dataset="{data($name)}" rulelastupdate="2019-08-19">Split dataset {data($name)} has a file name '{data($filename)}' that is typical for non-split datasets</error>
