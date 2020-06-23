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

(: Rule CG0546: SM: When MIDSTYPE = TM.MIDSTYPE and TM.TMRPT = 'Y', 
	then MIDS is suffixed with a sequence number in consistent chronological order
	REMARK: The rule does NOT say on what "Chronological order" should be based on - 
    we take SMSTDTC :)
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
(: get all the TM.MIDSTYPE values for which TMRPT='Y' :)
let $tmmidstypevalues := $tmdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tmrptoid and @Value='Y']]/odm:ItemData[@ItemOID=tmmidstypeoid]/@Value
(: iterate over SM datasets - there should be only 1 though:)
for $smitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='SM']
	let $name := $smitemgroupdef/@Name
    (: We need the OIDs of SM.USUBJID, of SM.MIDSTYPE and of SM.MIDS :)
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
    let $smmidsoid := (
        for $a in $definedoc//odm:ItemDef[@Name='MIDS']/@OID 
        where $a = $smitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the SM dataset location and the document itself :)
    let $smdatasetlocation := $smitemgroupdef/def:leaf/@xlink:href
    let $smdoc := (
    	if($smdatasetlocation) then doc(concat($base,$smdatasetlocation))
        else ()
    )
    (: iterate over all SM records for which MIDSTYPE
    has been declared in TM to have TMRPT='Y' :)
    for $record in $smdoc//odm:ItemGroupData[functx:is-value-in-sequence(odm:ItemData[@ItemOID=$smmidstypeoid]/@Value,$tmmidstypevalues)]
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of MIDS and of MIDSTYPE :)
        let $smmidsvalue := $record/odm:ItemData[@ItemOID=$smmidsoid]/@Value
        let $smmidstypevalue := $record/odm:ItemData[@ItemOID=$smmidstypeoid]/@Value
        (: we will check on the last and on the two last characters, 
        one of these needs to be a number :)
        let $midsvaluelength := string-length($smmidsvalue)
        let $lastchar := substring($smmidsvalue, $midsvaluelength)
        let $lasttwochars := substring($smmidsvalue, number($midsvaluelength)-1)
        let $endswithnumber := ($lastchar castable as xs:integer) or ($lasttwochars castable as xs:integer)
        let $midssequencenumber := (
        	if($lasttwochars castable as xs:integer) then number($lasttwochars)
            else if($lastchar castable as xs:integer) then number($lastchar)
            else () (: MIDS does not end with a number :)
        )        
        (: give an error when MIDS value does not end with a number :)
        (: TODO: check whether the number is in chronological order using MSSTDTC :)
        where not($endswithnumber)
        return <error rule="CG0546" dataset="{data($name)}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-22">Value of MIDS='{data($smmidsvalue)}' for MIDSTYPE='{data($smmidstypevalue)}' does not end with a number although the MIDSTYPE was declared as repeating in TM</error>

	
	