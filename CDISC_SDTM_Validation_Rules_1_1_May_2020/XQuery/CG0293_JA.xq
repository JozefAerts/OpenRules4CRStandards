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

(: Rule CG0293 - TV - When ARMCD != null then ARMCD in TA.ARMCD :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
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
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TA dataset definition :)
let $taitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TA']
(: we need the OID of the ARMCD variable in TA :)
let $taarmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID
        where $a = $taitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: and the dataset location :)
let $tadatasetlocation := (
	if($defineversion='2.1') then $taitemgroupdef/def21:leaf/@xlink:href
	else $taitemgroupdef/def:leaf/@xlink:href
)
let $tadatasetdoc := doc(concat($base,$tadatasetlocation))
(: get all the unique values of ARMCD in the TA dataset - this is a sequence (array) :)
let $taarmcdvalues := distinct-values($tadatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$taarmcdoid]/@Value)
(: iterate over the TV dataset definitions, there should be only 1 :)
for $tvitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TV']
    (: we need the OID of ARMCD in TV :)
    let $tvarmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID
        where $a = $tvitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location :)
	let $tvdatasetlocation := (
		if($defineversion='2.1') then $tvitemgroupdef/def21:leaf/@xlink:href
		else $tvitemgroupdef/def:leaf/@xlink:href
	)
    let $tvdatasetdoc := doc(concat($base,$tvdatasetlocation))
    (: iterate over all records in the TV dataset :)
    for $record in $tvdatasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARMCD in TV :)
        let $tvarmcd := $record/odm:ItemData[@ItemOID=$tvarmcdoid]/@Value
        (: TV.ARMCD must be one from TA.ARMCD, when TV.ARMCD is not null :)
        where $tvarmcd and not(functx:is-value-in-sequence($tvarmcd,$taarmcdvalues))
        return <error rule="CG0293" dataset="TV" variable="ARMCD" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">TV.ARMCD='{data($tvarmcd)}' is not found in the list of TA.ARMCD=({data($taarmcdvalues)})</error>									
		
	