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

(: Rule CG0367 - When RSUBJID !=null and RSUBJID != POOLID then RSUBJID = DM.USUBJID :)
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
(: get the DM dataset, and get all values of USUBJID in it (as a sequence/array) :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: we need the OID of USUBJID :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the DM dataset location and the document :)
let $dmdatasetlocation := (
	if($defineversion='2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: now get all the values of USUBJID in DM :)
let $usubjidvalues := $dmdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$usubjidoid]/@Value  (: returns all values as a sequence/array :)
(: iterate over all AP datasets :)
for $apitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'AP')]
    let $name := $apitemgroupdef/@Name
    (: we need the OID of RSUBJID and POOLID :)
    let $rsubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RSUBJID']/@OID 
        where $a = $apitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $poolidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = $apitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the location and document of the dataset :)
	let $apdatasetlocation := (
		if($defineversion='2.1') then $apitemgroupdef/def21:leaf/@xlink:href
		else $apitemgroupdef/def:leaf/@xlink:href
	)
    let $apdatasetdoc := doc(concat($base,$apdatasetlocation))
    (: iterate over all records for which RSUBJID !=null and RSUBJID != POOLID :)
    for $record in $apdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rsubjidoid] and odm:ItemData[@ItemOID=$poolidoid] 
        and odm:ItemData[@ItemOID=$rsubjidoid]/@Value != odm:ItemData[@ItemOID=$poolidoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of RSUBJID and of POOLID for reporting :)
        let $rsubjid := $record/odm:ItemData[@ItemOID=$rsubjidoid]/@Value
        let $poolid := odm:ItemData[@ItemOID=$poolidoid]/@Value
        (: RSUBJID value must also be present in DM as USUBJID :)
        where not(functx:is-value-in-sequence($rsubjid,$usubjidvalues))
        return <error rule="CG0367" dataset="{data($name)}" variable="RSUBJID" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of RSUBJID='{data($rsubjid)}' was not found as USUBJID in DM dataset although RSUBJID != POOLID='{data($poolid)}'</error>			
		
	