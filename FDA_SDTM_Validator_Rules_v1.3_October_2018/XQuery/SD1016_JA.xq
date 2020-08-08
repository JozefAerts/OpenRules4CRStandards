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

(: Rule SD1016: The combination of Inclusion/Exclusion Criterion Short Name (IETESTCD), Criterion (IETEST), and Category (IECAT) values should match entries in the Trial Inclusion/Exclusion Criteria (TI) dataset :)
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
let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' 
let $definedoc := doc(concat($base,$define))  
(: Get the IE dataset :)
let $iedataset := $definedoc//odm:ItemGroupDef[@Name='IE']
let $iedatasetname := (
	if($defineversion = '2.1') then $iedataset/def21:leaf/@xlink:href
	else $iedataset/def:leaf/@xlink:href
)
let $iedatasetlocation := concat($base,$iedatasetname)
let $iedatasetdoc := doc($iedatasetlocation)
(: get the TI dataset :)
let $tidataset := $definedoc//odm:ItemGroupDef[@Name='TI']
let $tidatasetlocation := (
	if($defineversion = '2.1') then $tidataset/def21:leaf/@xlink:href
	else $tidataset/def:leaf/@xlink:href
)
let $tidatasetdoc := doc(concat($base,$tidatasetlocation))
(: get the OID of TI.TITESTCD, TI.IETEST, and TI.TICAT :)
let $titestcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETESTCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TI']/odm:ItemRef/@ItemOID
    return $a
)
let $titestoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETEST']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TI']/odm:ItemRef/@ItemOID
    return $a
)
let $ticatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TICAT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TI']/odm:ItemRef/@ItemOID
    return $a
)
(: get all the values of TI.IETEST - this is a sequence (array) :)
(: let $tiietestvalues := $tidatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tiietestoid]/@Value :)
(: generate a temporary structure containing all the triples from TI :)
let $titriples := (
    for $record in $tidatasetdoc//odm:ItemGroupData
    let $titestcd := $record/odm:ItemData[@ItemOID=$titestcdoid]/@Value
    let $titest := $record/odm:ItemData[@ItemOID=$titestoid]/@Value
    let $ticat := $record/odm:ItemData[@ItemOID=$ticatoid]/@Value
    return <record titestcd="{$titestcd}" titest="{$titest}" ticat="{$ticat}" />
)

(: get the OID of IETESTCD, IETEST and IECAT in the IE dataset :)
let $ietestcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETESTCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
    return $a
)
let $ietestoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETEST']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
    return $a
)
let $iecatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IECAT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all the records in the IE dataset :)
for $record in $iedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of ITESTCD, IETEST and IECAT in IE :)
    let $ietestcd := $record/odm:ItemData[@ItemOID=$ietestcdoid]/@Value
    let $ietest := $record/odm:ItemData[@ItemOID=$ietestoid]/@Value
    let $iecat := $record/odm:ItemData[@ItemOID=$iecatoid]/@Value
    (: match with the values in the temporary structure  :)
    let $count := count ($titriples/record[@titestcd=$ietestcd and @titest=$ietest and @ticat=$iecat])
    (: there must be a match :)
    where $count = 0
    return <error rule="SD1016" dataset="IE" variable="IETEST" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">The combination IETESTCD='{data($ietestcd)}', IETEST='{data($ietest)}' and IECAT='{data($iecat)}' cannot be found in the TI dataset</error>
		
	