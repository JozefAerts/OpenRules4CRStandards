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

(: Rule SD1230: Variable datatype is not %Variable.@Clause.DataType% when value-level condition occurs - 
 Value level datatype must match the datatype described in define.xml :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
 } ;
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
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external; 
(: find all dataset definitions  :)
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml'
let $datasetname := 'EG' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: get the location of the dataset and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the coded ValueList variables for this dataset
    We currently still need to exclude "External" CodeLists as long as they do not have a RESTful WS available,
    and as long as ODM/Dataset-XML does not support RESTful web services :)
    (: get the variables (OIDs) that do have an attached ValueList for this dataset :)
    let $valuelistvars := (
        for $a in $definedoc//odm:ItemDef[def:ValueListRef/@ValueListOID]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    (: return <test>{data($valuelistvars)}</test> :)
    (: iterate over the variables (OIDs) that do have an attached ValueList :)
    for $valuelistvar in $valuelistvars
        (: get the Name of the variable :)
        let $valuelistvarname := $definedoc//odm:ItemDef[@OID=$valuelistvar]/@Name
        (: get the reference valuelist itself :)
        let $valuelistoid := $definedoc//odm:ItemDef[@OID=$valuelistvar]/def:ValueListRef/@ValueListOID
        let $valuelist := $definedoc//def:ValueListDef[@OID=$valuelistoid]
        (: iterate over the ValueList ItemRefs :)
        for $valuelistitemref in $valuelist/odm:ItemRef[@Mandatory='Yes']
            (: get the OID :)
            let $valuelistitemoid := $valuelistitemref/@ItemOID
            (: get the WhereClause :)
            let $whereclauserefoid := $valuelistitemref/def:WhereClauseRef/@WhereClauseOID
            (: and the corresponding WhereClauseDef :)
            let $whereclausedef := $definedoc//def:WhereClauseDef[@OID=$whereclauserefoid]
            (: get the item it is about - we currently only support 1 item and only the "EQ" comparator,
            and only the case that it is about data in the same dataset (e.g. STRESU depends of TESTCD value)
            This covers 90% of the cases :)
            let $whereclauseaboutitemoid := $whereclausedef/odm:RangeCheck/@def:ItemOID
            let $whereclauseaboutitemname := $definedoc//odm:ItemDef[@OID=$whereclauseaboutitemoid]/@Name
            let $checkvalue := $whereclausedef/odm:RangeCheck/odm:CheckValue/text()
            (: return <test>{data($whereclauseaboutitemoid)} - {data($checkvalue)}</test> :)
            (: pick up the corresponding ItemDef :)
            for $valuelistitemdef in $definedoc//odm:ItemDef[@OID=$valuelistitemoid]
                (: get the datatype :)
                let $datatype := $valuelistitemdef/@DataType
                (: get all the records in the dataset that are about the given valuelist variable :)
                (: return <test>{data($valuelistvar)} - {data($whereclauseaboutitemoid)} - {data($checkvalue)} - {data($valuelistcodedvalues)}</test> :)
                (: iterate over all the records where the WhereClause applies to, 
                i.e. $whereclauseaboutitemoid = $checkvalue :)
                for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$whereclauseaboutitemoid and @Value=$checkvalue]]
                    let $recnum := $record/@data:ItemGroupDataSeq
                    (: get the value of the dependent variable :)                  
                    let $itemvalue := $record/odm:ItemData[@ItemOID=$valuelistvar]/@Value
                    (: the value must be according to the datatype :)
                    (: define.xml allows following datatypes:
                    text, integer, float, datetime, date, time, partialDate, partialTime, partialDatetime, 
                    incompleteDatetime, durationDatetime
                    :)
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
                    (: when the value does not match the datatype, give an error  :)
                    where $isValidDataTypeValue = 'false'
                    return <error rule="SD1230" dataset="{$datasetname}" variable="{$valuelistvarname}" recordnumber="{$recnum}" rulelastupdate="2019-08-17">Variable {data($valuelistvarname)} valuelist value '{data($itemvalue)}' is compatible with its data type '{data($datatype)}'</error>

