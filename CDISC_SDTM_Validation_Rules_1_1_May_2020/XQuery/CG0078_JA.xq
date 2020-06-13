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

(: Rule CG0078: When MHENDTC != null then MHENDTC < DM.RFSTDTC :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the MH dataset - take splitted domains into account :)
let $mhitemgroupdef := $definedoc//odm:ItemGroupDef[starts-with(@Name,'MH') or @Domain='MH']
let $name := $mhitemgroupdef/@Name
let $mhdatasetlocation := $mhitemgroupdef/def:leaf/@xlink:href
let $mhdatasetdoc := doc(concat($base,$mhdatasetlocation))
(: get the OID of MHENDTC and of USUBJID in MH :)
let $mhendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MHENDTC']/@OID 
    where $a = $mhitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $mhusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $mhitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: Get the DM dataset and its location :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: and the OID of USUBJID and of RFSTDTC :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in the MH dataset that have MHENDTC not null :)
for $record in $mhdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$mhendtcoid and @Value != '']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID and of MHENDTC for this record :)
    let $usubjid := $record/odm:ItemData[@ItemOID=$mhusubjidoid]/@Value
    let $mhendtc := $record/odm:ItemData[@ItemOID=$mhendtcoid]/@Value
    (: look up the corresponding DM record - there should be only one :)
    let $dmrecord := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]][1]
    (: and get the value of RFSTDTC :)
    let $rfstdtc := $dmrecord/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
    (: in case MHENDTC is a partial date, we must do something :)
    (: when only the year is present, -01-01 is added, when year and month are present, -01 is added.
    This will take care that 'in case of doubt', no error is thrown :)
    let $mhendtccomplete := (
        if(string-length($mhendtc)=4) then concat($mhendtc,'-01-01')
        else if(string-length($mhendtc)=7) then concat($mhendtc,'-01')
        else $mhendtc
    )
    (: compare the dates, take care that both really are complete dates. 
    give an error when MHENDTC > RFSTDTC :)

    where $rfstdtc castable as xs:date and $mhendtccomplete castable as xs:date and not(xs:date($mhendtccomplete) <= xs:date($rfstdtc))
    return <error rule="CG0078" variable="MHENDTC" dataset="{data($name)}" rulelastupdate="2020-06-11" recordnumber="{data($recnum)}">MHENDTC={data($mhendtc)} is after or on RFSTDTC={data($rfstdtc)}</error>
		
	