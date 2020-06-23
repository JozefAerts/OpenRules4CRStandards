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

(: Rule CG0545: SM: When MIDSTYPE = TM.MIDSTYPE and TM.TMRPT = 'N', 
	then MIDSTYPE is unique per subject :)
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
(: we need the OIDs of TM.MIDSTYPE and TM.TMRPT :)
let $tmitemgroupdef := $definedoc//odm:ItemGroupData[@Name='TM']
let $tmmidstypeoid := (
	for $a in $definedoc//odm:ItemDef[@Name='MIDSTYPE']/@OID 
        where $a = $tmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $tmrptoid := (
	for $a in $definedoc//odm:ItemDef[@Name='TMRPT']/@OID 
        where $a = $tmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the location of the TM dataset and the document itself :)
let $tmdatasetlocation := $definedoc//odm:ItemGroupDef[@Name='TM']
let $tmdoc := (
	if($tmdatasetlocation) then doc(concat($base,$tmdatasetlocation))
    else ()
)
(: get all the TM.MIDSTYPE values for which TMRPT='N' :)
let $tmmidstypevalues := $tmdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tmrptoid and @Value='N']]/odm:ItemData[@ItemOID=tmmidstypeoid]/@Value
(: iterate over SM datasets - there should be only 1 though:)
for $smitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='SM']
	let $name := $smitemgroupdef/@Name
    (: We need the OIDs of SM.USUBJID and of SM.MIDSTYPE:)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $smitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $smmidstypeoid := (
        for $a in $definedoc//odm:ItemDef[@Name='MIDSTYPE']/@OID 
        where $a = $smitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the SM dataset location and the document itself :)
    let $smdatasetlocation := $smitemgroupdef/def:leaf/@xlink:href
    let $smdoc := (
    	if($smdatasetlocation) then doc(concat($base,$smdatasetlocation))
        else ()
    )
    (: group all records in SM by USUBJID and SM.MIDSTYPE :)
    let $groupedrecords := (
      for $record in $smdoc//odm:ItemGroupData
      group by 
          $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
          $b := $record/odm:ItemData[@ItemOID=$smmidstypeoid]/@Value
          return element group {  
              $record
          }
	)
    (: iterate over all the groups, each group contains the records of a single subject :)
    for $group in $groupedrecords
    	(: get the value of SM.MIDSTYPE - all the records in the group have the same value for MIDSTYPE :)
        let $smmidstypevalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$smmidstypeoid]/@Value
        (: and the value of USUBJID :)
        let $usubjidvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: count the number of records in thuis group :)
        let $count := count($group/odm:ItemGroupData)
        (: return an error when MIDSTYPE is one of TM.MIDTYPE with TMRPT='N' 
        AND the number of records > 1 :)
        where functx:is-value-in-sequence($smmidstypevalue,$tmmidstypevalues) and $count > 1
        return <error rule="CG0545" dataset="{data($name)}" rulelastupdate="2020-06-22">More than 1 MIDSTYPE='{data($smmidstypevalue)}' record was found for subject with USUBJID='{data($usubjidvalue)}' although the MIDSTYPE was declared as non-repeating in TM</error>
	
	