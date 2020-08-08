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

(: Rule SD0059 - Define.xml/dataset variable type mismatch: 
Variable Data Types in the dataset must match the variable data types described in the data definition document (define.xml)
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
declare variable $datasetname external;
(: some own local functions :)
declare function functx:isPartialDatetime
  ( $arg as xs:string? ) as xs:boolean {
   let $testvalue := 
        (: only the year is given :)
        if(string-length($arg) = 4) then concat($arg,'-01-01T00:00:00')
        (: only the year and month is given :)
        else if(string-length($arg) = 7) then concat($arg,'-01T00:00:00')
        (: date is complete but time part is missing :)
        else if(string-length($arg) = 10) then concat($arg,'T00:00:00')
        (: data is complete but only hour is given :)
        else if(string-length($arg) = 14) then concat($arg,':00:00')
        (: date, hour and minutes are given, but seconds is missing :)
        else if(string-length($arg) = 17) then concat($arg,':00')
        (: date seems to be complete :)
        else $arg 
    return $testvalue castable as xs:date
 } ;
declare function functx:isPartialDate ( $arg as xs:string? ) as xs:boolean {
    let $testvalue := 
        (: only the year is given :)
        if(string-length($arg) = 4) then concat($arg,'-01-01')
        (: only year and month is given :)
        else if(string-length($arg) = 7) then concat($arg,'-01')
        (: date seems to be complete :)
        else $arg 
    return $testvalue castable as xs:date
 } ;
declare function functx:isPartialTime ( $arg as xs:string? ) as xs:boolean {
    let $testvalue := 
        (: only the hour is given :)
        if(string-length($arg) = 4) then concat($arg,':00:00')
        (: only hour and minutes are given :)
        else if(string-length($arg) = 7) then concat($arg,':00')
        (: time seems to be complete :)
        else $arg 
    return $testvalue castable as xs:time
 } ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: let $datasetname := 'ALL' :)
(: EITHER provide $datasetname := 'ALL', meaning: validate for all domains referenced from the define.xml OR:
$datasetname:='XX' where XX is a specific dataset name, MEANING validate for a single dataset only :)
(:  get the definitions for the domains (ItemGroupDefs in define.xml) :)
let $datasets := (
    if($datasetname != 'ALL') then $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    else $definedoc//odm:ItemGroupDef
)
(: iterate over all datasets :)
for $dataset in $datasets
	let $dsname := $dataset/@Name
    let $datasetlocation := (
		if($defineversion = '2.1') then concat($base,$dataset/def21:leaf/@xlink:href)
		else concat($base,$dataset/def:leaf/@xlink:href)
	)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over all datapoints in the record, get OID and value :)
        for $datapoint in $record/odm:ItemData
            let $itemoid := $datapoint/@ItemOID
            let $itemvalue := $datapoint/@Value
            (: get the datatype in the corresponding ItemDef :)
            let $datatype := $definedoc//odm:ItemDef[@OID=$itemoid]/@DataType
            let $varname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
            (: define.xml allows following datatypes:
            text, integer, float, datetime, date, time, partialDate, partialTime, partialDatetime, 
            incompleteDatetime, durationDatetime
            :)
            (: $isValidDataTypeValue is boolean :)
			(: P.S. in case 'datetime' is expected but a correct date is provided, that is also ok :)
            let $isValidDataTypeValue := 
                if ($datatype = 'text') then 'true'   (: everything is text ... :)
                else if($datatype = 'integer' and $itemvalue castable as xs:integer) then 'true'
                else if($datatype = 'float' and $itemvalue castable as xs:double) then 'true'
                else if($datatype = 'datetime' and $itemvalue castable as xs:dateTime) then 'true' 
                else if($datatype = 'date' and $itemvalue castable as xs:date or $itemvalue castable as xs:date) then 'true'
                else if($datatype = 'time' and $itemvalue castable as xs:time) then 'true'
                (: use function for partialDate :)
                else if($datatype = 'partialDate' and functx:isPartialDate($itemvalue)) then 'true'
                (: use function for partialTime :)
                else if($datatype = 'partialTime' and functx:isPartialTime($itemvalue)) then 'true'
                (: use function for partialDateTime :)
                else if($datatype = 'partialDateTime' and functx:isPartialDatetime($itemvalue)) then 'true' 
                (: TODO: write function for incompleteDatetime :)
                else if($datatype = 'durationDatetime' and $itemvalue castable as xs:duration) then 'true'
                (: TODO: write function for other form of durationDatetime ("from-to" format) :)
                else 'false'
            where $isValidDataTypeValue = 'false'
            return <error rule="SD0059" dataset="{data($dsname)}" variable="{data($varname)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Define.xml/dataset variable type mismatch - Data point with OID = {data($itemoid)} and name = {data($varname)} and value {data($itemvalue)} is expected to be of type {data($datatype)}</error>
