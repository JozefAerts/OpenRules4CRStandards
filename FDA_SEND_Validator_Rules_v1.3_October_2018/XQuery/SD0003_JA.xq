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

(: Rule SD0003 - Invalid ISO 8601 value for *DTC variable :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: need a function substring-after-last - see e.g. http://www.xqueryfunctions.com/xq/functx_substring-after-last.html :)
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: FUNCTION DECLARATIONS :)
declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all dataset declarations using the ItemGroupDef nodes in the define.xml :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
let $itemgroupdefoid := $itemgroupdef/@OID
let $itemgroupdefname := $itemgroupdef/@Name
(: get the dataset document :)
let $datasetlocation := (
	if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
	else $itemgroupdef/def:leaf/@xlink:href
)
let $doc := (
	if($datasetlocation) then doc(concat($base,$datasetlocation))
	else ()
)
(: get the Items for which the name ends with DTC :)
for $itemoid in $itemgroupdef/odm:ItemRef/@ItemOID
    for $itemdefdatetimetype in $itemgroupdef/../odm:ItemDef[@OID=$itemoid][ends-with(@Name,'DTC')]
        let $itemoiddtc := $itemdefdatetimetype/@OID
        let $itemname := $itemgroupdef/../odm:ItemDef[@OID=$itemoid]/@Name
        (: and now find them in the dataset itself :)
        for $itemdata in $doc//odm:ItemData[@ItemOID=$itemoiddtc]
            let $recnum := $itemdata/../@data:ItemGroupDataSeq
            let $value := $itemdata/@Value
            
            (: allow for partial dates and datetimes :)
            let $testvalue :=
                (: only the year is given :)
                if(string-length($value) = 4) then concat($value,'-01-01')
                (: only the month is given :)
                else if(string-length($value) = 7) then concat($value,'-01')
                (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($value) = 11) then concat($value,'00:00:00')
                (: only hour is given :)
                else if(string-length($value) = 13) then concat($value,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($value) = 16) then concat($value,':00')
                (: all ok anyway :)
                else ($value)
            where not($testvalue castable as xs:date) and not($testvalue castable as xs:dateTime )
            return <error rule="SD0003" dataset="{data($itemgroupdefname)}" variable="{data($itemname)}" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">invalid ISO-8601 value for variable {data($itemname)} value = {data($value)} in dataset {data($itemgroupdefname)}</error>	
