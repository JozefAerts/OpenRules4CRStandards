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

(: Rule SE2311: Set Code (SETCD) values should match entries in the Trial Sets (TX) dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
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
(: let $base := 'SEND_3_0_PC201708/' :)
(: let $define := 'define.xml' :)
(: the define.xml document itself :)
let $definedoc := doc(concat($base,$define))
(: First get the DM dataset, and get the OID of SETCD :)
let $dmsetcdoid := (
	for $a in $definedoc//odm:ItemDef[@Name='SETCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: Get the DM document :)
let $dmloc := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdoc := doc(concat($base,$dmloc))
(: we need the OID of SETCD in TX :)
let $txsetcdoid := (
	for $a in $definedoc//odm:ItemDef[@Name='SETCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='TX']/odm:ItemRef/@ItemOID
        return $a
)
(: Get the TX document :)
let $txloc := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='TX']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='TX']/def:leaf/@xlink:href
)
let $txdoc := (
	if($txloc) then doc(concat($base,$txloc))
    else () (: TX is not present :)
)
(: get all the unique SETCD values in TX :)
let $txsetcdvalues := distinct-values($txdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$txsetcdoid]/@Value)
(: Iterate over all the DM records that have SETCD populated :)
for $record in $dmdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmsetcdoid]]
	let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of SETCD :)
    let $dmsetcdvalue := $record/odm:ItemData[@ItemOID=$dmsetcdoid]/@Value
    (: value must be one of the TX.SETCD values :)
    where not(functx:is-value-in-sequence($dmsetcdvalue,$txsetcdvalues))
    return <error rule="SE2311" dataset="DM" variable="SETCD" recordnumber="{data($recnum)}" rulelastupdate="2020-06-26">DM.SETCD value '{data($dmsetcdvalue)}' cannot be found in TX</error>

