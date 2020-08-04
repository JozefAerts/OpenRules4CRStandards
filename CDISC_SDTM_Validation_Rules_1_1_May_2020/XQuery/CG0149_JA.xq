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

(: Rule CG0149 - SETCD value length <= 8 :)
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
(: sorting function - also sorts dates :)
declare function functx:sort
  ( $seq as item()* )  as item()* {

   for $item in $seq
   order by $item
   return $item
 } ;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := (
	if($defineversion='2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of SETCD in DM :)
let $setcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SETCD']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: we may also need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: iterate over all the records in DM that have a value for SETCD :)
for $dmrecord in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$setcdoid]]
    let $recnum := $dmrecord/@data:ItemGroupDataSeq
    (: get the value of SETCD :)
    let $setcdvalue := $dmrecord/odm:ItemData[@ItemOID=$setcdoid]/@Value
    (: get the value of USUBJID - not necessarily needed :)
    let $dmusubjid := $dmrecord/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    (: SETCD value length <= 8 :)
    where string-length($setcdvalue) > 8
    return <error rule="CG0149" variable="SETCD" dataset="DM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">SETCD='{data($setcdvalue)}' has more than 8 characters</error>				
		
	