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

(: Rule CG0294 - TV - When ARM != null then ARM in TA.ARM :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TA dataset definition :)
let $taitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TA']
(: we need the OID of the ARM variable in TA :)
let $taarmoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID
        where $a = $taitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: and the dataset location :)
let $tadatasetlocation := $taitemgroupdef/def:leaf/@xlink:href
let $tadatasetdoc := doc(concat($base,$tadatasetlocation))
(: get all the unique values of ARM in the TA dataset - this is a sequence (array) :)
let $taarmvalues := distinct-values($tadatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$taarmoid]/@Value)
(: iterate over the TV dataset definitions, there should be only 1 :)
for $tvitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TV']
    (: we need the OID of ARM in TV :)
    let $tvarmoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID
        where $a = $tvitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location :)
    let $tvdatasetlocation := $tvitemgroupdef/def:leaf/@xlink:href
    let $tvdatasetdoc := doc(concat($base,$tvdatasetlocation))
    (: iterate over all records in the TV dataset :)
    for $record in $tvdatasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARM in TV :)
        let $tvarm := $record/odm:ItemData[@ItemOID=$tvarmoid]/@Value
        (: TV.ARM must be one from TA.ARM, when TV.ARM is not null :)
        where $tvarm and not(functx:is-value-in-sequence($tvarm,$taarmvalues))
        return <error rule="CG0294" dataset="TV" variable="ARM" recordnumber="{data($recnum)}" rulelastupdate="2017-03-01">TV.ARM='{data($tvarm)}' is not found in the list of TA.ARM=({data($taarmvalues)})</error>								
		
		