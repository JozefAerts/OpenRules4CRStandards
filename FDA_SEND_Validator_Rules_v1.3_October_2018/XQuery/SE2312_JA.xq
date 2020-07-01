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

(: Rule SE2312: Pool ID (POOLID) values should match entries in the Pool Definition (POOLDEF) dataset :)
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
(: let $base := 'SEND_3_0_PC201708/'  :)
(: let $define := 'define.xml' :)
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
let $definedoc := doc(concat($base,$define))
(: get all unique POOLID values within POOLDEF :)
let $pooldef := $definedoc//odm:ItemGroupDef[@Name='POOLDEF']
let $pooldefdoc := (
	if($pooldef/def:leaf/@xlink:href) then doc(concat($base,$pooldef/def:leaf/@xlink:href))
    else ()  (: No POOLDEF dataset :)
)
let $poolidoid := (
	for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = $pooldef/odm:ItemRef/@ItemOID
        return $a
)
let $pooldefpoolids := distinct-values($pooldefdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$poolidoid]/@Value)
(: get all EX, CL, FW, LB, PC, PP, RELREC, SUPP-- datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Domain='EX' or starts-with(@Name,'EX') 
      or @Domain='CL' or starts-with(@Name,'CL') 
      or @Domain='FW' or starts-with(@Name,'FW') 
      or @Domain='LB' or starts-with(@Name,'LB') 
      or @Domain='PC' or starts-with(@Name,'PC') 
      or @Domain='PP' or starts-with(@Name,'PP')
      or @Name='RELREC'
      or starts-with(@Name,'SUPP') ]
	let $name := $itemgroupdef/@Name
    (: get the OID of POOLID in the dataset definition :)
    let $dspoolidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and document :)
    let $dsloc := $itemgroupdef/def:leaf/@xlink:href
    let $dsdoc := doc(concat($base,$dsloc))
    (: iterate over all records in the dataset, 
    and get the value of POOLID :)
    for $record in $dsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dspoolidoid]]
    	let $recnum := $record/@data:ItemGroupDataSeq
        let $poolidvalue := $record/odm:ItemData[@ItemOID=$dspoolidoid]/@Value
        (: Value must be one of POOLDEF.POOLID :)
    	where not(functx:is-value-in-sequence($poolidvalue,$pooldefpoolids))
        return <error rule="SE2312" dataset="{data($name)}" variable="POOLID" recordnumber="{data($recnum)}" rulelastupdate="2020-06-26">POOLID value '{data($poolidvalue)}' is not found as a POOLDEF.POOLID value</error> 

