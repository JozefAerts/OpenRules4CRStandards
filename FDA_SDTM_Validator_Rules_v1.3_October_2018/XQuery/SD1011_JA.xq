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

(: Rule SD1011 - Value --DUR, --ELTM, --EVLINT must conform to the ISO 8601 "duration" international standard
Value of Duration, Elapsed Time, and Interval variables (--DUR, --ELTM, --EVLINT) must conform to the ISO 8601 international standard
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over ALL datasets :)
for $dataset in $definedoc//odm:ItemGroupDef
let $datasetname := (
	if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
	else $dataset/def:leaf/@xlink:href
)
let $datasetlocation := concat($base,$datasetname)
(: get the OIDs of the --DUR, --ELTM and --EVLINT variables.
 Also get the variable name :)
let $duroid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DUR')]/@OID 
    where $a = $dataset/odm:ItemRef/@ItemOID
    return $a
)
let $durname := $definedoc//odm:ItemDef[@OID=$duroid]/@Name
let $eltmoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
    where $a = $dataset/odm:ItemRef/@ItemOID
    return $a
)
let $eltmname := $definedoc//odm:ItemDef[@OID=$eltmoid]/@Name
let $evlintoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'EVLINT')]/@OID 
    where $a = $dataset/odm:ItemRef/@ItemOID
    return $a
)
let $evlintname := $definedoc//odm:ItemDef[@OID=$evlintoid]/@Name
(:  return <test>{data($durname)} - {data($eltmname)} - {data($evlintname)}</test> :)
(: iterate over all records that have either a value for --DUR, --ELTM or --EVLINT :)
for $record in doc($datasetlocation)[$duroid or $eltmoid or $evlintoid]//odm:ItemGroupData
    (: get the record number :)
    let $recnum := $record/@data:ItemGroupDataSeq
    (: iterate over all the datapoints --DUR, --ELTM, --EVLINT :)
    let $durdatapoints := $record/odm:ItemData[@ItemOID=$duroid or @ItemOID=$eltmoid or @ItemOID=$evlintoid]
    for $datapoint in $durdatapoints
        (: get the value :)
        let $value := $datapoint/@Value
        (: we need the name of the datapoint in the define.xml for reporting :)
        let $itemoid := $datapoint/@ItemOID
        let $itemname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
        (: the value must be a valid ISO-8601 "duration" :)
        (: IMPORTANT: PnW and -PnW are rejected as valid ISO-8601 durations, so we need to take care of that :)
        (: TODO: check the "n" is an integer :)
        where not($value castable as xs:duration) and not((starts-with($value,'P') or starts-with($value,'-P')) and ends-with($value,'W'))
        return <error rule="SD1011" dataset="{data($datasetname)}" variable="{$itemname}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid (non-ISO8601 duration) value='{data($value)}'</error>

