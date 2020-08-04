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

(: Rule CG0402 - --TEST length <= 40 (except for IE) - 
Findings domains except for IE :)
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
(: iterate over all FINDINS domains, except IE :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS'][not(starts-with(@Name,'IE'))]
    let $name := $itemgroupdef/@Name
    (: get the OID of --TEST :)
    let $testoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TEST')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $testname := $definedoc//odm:ItemDef[@OID=$testoid]/@Name
    (: get the dataset location and document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all records - --TEST is a required variable :)
    for $record in $datasetdoc//odm:ItemGroupData
        (: get the record number :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --TEST :)
        let $test := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        (: --TEST may not have more than 40 characters :)
        where string-length($test) > 40
        return <error rule="CG0406" dataset="{data($name)}" variable="{data($testname)}" rulelastupdate="2020-08-04">The value of {data($testname)} has more than 40 characters. {data($testname)}='{data($test)}' was found</error>												
		
	