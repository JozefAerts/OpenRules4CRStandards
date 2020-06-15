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

(: Rule CG0157-CG0158: 
Rules CG0157 and CG0158 have been combined, as otherwise they are not implementable in software,
as we cannot know in advance whether an RSUBJID either belongs to a single person or to a pool.
From the SDTM-IG AP 1.0: "RSUBJID will be populated with the USUBJID of the related subject OR the POOLID of the related pool.
The rule does not apply to the case that the relation is to another study as a whole,
but there is no way to find out that from SREL (Subject, Device, or Study Relationship)
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) of values :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM and POOLDEF datasets :)
let $dm := $definedoc//odm:ItemGroupDef[@Name='DM']
let $pooldef := $definedoc//odm:ItemGroupDef[@Name='POOLDEF']
(: In DM, we need the OID of the USUBJID variable,
in POOLDEF, we need the OID of the POOLID variable :)
let $dmusubjidoid := (
	for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dm/odm:ItemRef/@ItemOID
        return $a
)
let $poolidoid := (
	for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = $pooldef/odm:ItemRef/@ItemOID
        return $a
)
(: and we need the DM and POOLDEF datasets themselves :)
let $dmdatasetlocation := $dm/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
let $pooldefdatasetlocation := $pooldef/def:leaf/@xlink:href
let $pooldefdatasetdoc := (
	if ($pooldefdatasetlocation) then doc(concat($base,$pooldefdatasetlocation))
    else ()
)
(: First, get all values of USUBJID in DM, 
and of POOLID in POOLDEF :)
let $dmusubjidvalues := $dmdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
let $poolsetpoolidvalues := $pooldefdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$poolidoid]/@Value
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'AP') and not(@Name='APRELSUB')]
    let $name := $itemgroupdef/@Name
    (: get the dataset location :)
    let $apdatasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $apdatasetdoc := doc(concat($base,$apdatasetlocation))
    (: we need the OID of RSUBJID :)
    let $rsubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RSUBJID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the AP dataset and get the value of RSUBJID :)
    for $record in $apdatasetdoc//odm:ItemGroupData
    	let $recnum := $record/@data:ItemGroupDataSeq
        let $rsubjid := $record/odm:ItemData[@ItemOID=$rsubjidoid]/@Value
        (: RSUBJID must either be one of DM.USUBJID or POOLDEF.POOLID :)
        where not(functx:is-value-in-sequence($rsubjid,$dmusubjidvalues)) or not(functx:is-value-in-sequence($rsubjid,$poolsetpoolidvalues))
        return <error rule="CG0157-CG0158" dataset="{data($name)}" variable="RSUBJID" recordnumber="{data($recnum)}" rulelastupdate="2020-06-16">Value of RSUBJID '' cannot be found in DM.USUBJID nor in POOLDEF.POOLID</error>
	
	