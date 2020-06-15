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

(: Rule CG0178 - IETEST in TI.IETEST :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))  

(: get the OID of TI.IETEST :)
let $tiietestoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETEST']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TI']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID IETEST in the IE dataset :)
let $ieietestoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IETEST']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
    return $a
)
(: get the TI dataset :)
let $tidataset := $definedoc//odm:ItemGroupDef[@Name='TI']
let $tidatasetlocation := $tidataset/def:leaf/@xlink:href
let $tidatasetdoc := doc(concat($base,$tidatasetlocation))
(: get all the values of TI.IETEST - this is a sequence (array) :)
let $tiietestvalues := $tidatasetdoc[$tiietestoid]//odm:ItemGroupData/odm:ItemData[@ItemOID=$tiietestoid]/@Value
(: Get the IE dataset :)
let $iedataset := $definedoc//odm:ItemGroupDef[@Name='IE']
let $iedatasetname := $iedataset/def:leaf/@xlink:href
let $iedatasetlocation := concat($base,$iedatasetname)
let $iedatasetdoc := doc(concat($base,$iedatasetlocation))[$ieietestoid]
(: iterate over all the records in the IE dataset :)
for $record in $iedatasetdoc[$ieietestoid]//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of IETEST in IE :)
    let $ieietest := $record/odm:ItemData[@ItemOID=$ieietestoid]/@Value
    (: IETEST in TI.IETEST :)
    where not(functx:is-value-in-sequence($ieietest,$tiietestvalues))
    return <error rule="CG0178" dataset="IE" variable="IETEST" rulelastupdate="2020-06-14" recordnumber="{data($recnum)}">Value of IE.IETEST={data($ieietest)} cannot be found in the TI dataset</error>				
	
	