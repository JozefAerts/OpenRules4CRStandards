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

(: Rule CG0034: when VISITNUM != null then VISITNUM must in SV.VISITNUM :)
(: Single dataset version :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the SV dataset :)
let $svdatasetname := $definedoc//odm:ItemGroupDef[@Name='SV']/def:leaf/@xlink:href
let $svdatasetdoc := doc(concat($base,$svdatasetname))
(: get the OID of USUBJID in SV :)
let $svusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of VISITNUM in SV :)
let $svvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of VISIT in SV :)
let $svvisitoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='SV']/odm:ItemRef/@ItemOID
    return $a
)
(: Create an interim structure containing SV USUBJID-VISITNUM pairs.
 This avoids that the SV dataset needs to be opened over and over again.
 This reduces the querying time by a factor 4 :)
let $visitnumpairs := (
    for $svrecord in $svdatasetdoc//odm:ItemGroupData
        let $usubjid := $svrecord/odm:ItemData[@ItemOID=$svusubjidoid]/@Value
        let $visitnum := $svrecord/odm:ItemData[@ItemOID=$svvisitnumoid]/@Value
        return <svrecord usubjid="{$usubjid}" visitnum="{$visitnum}" />
)
(: iterate over all the datasets for which there is subject data - except for SV itself :)
for $itemgroup in $definedoc//odm:ItemGroupDef[not(@Name='SV')][@Name=$datasetname]
	let $datasetname := $itemgroup/@Name
    (: get the location :)
    let $datasetlocation := $itemgroup/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of USUBJID, VISITNUM, if present :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID
        return $a
    )
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID
        return $a
    )
    (: further improvement 2019-08-11: group all the records by USUBJID and VISITNUM,
    so that all records in each group have the same values for USUBJID and VISITNUM. 
    We then only need to check the first record in the group. 
    If the USUBJID-VISITNUM pair is not found in SV,
    generate an error for each record in that group :)
    let $orderedrecords := (
    for $record in $datasetdoc[$usubjidoid and $visitnumoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid] and odm:ItemData[@ItemOID=$visitnumoid]]
        group by
        $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $c := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        return element group {  
            $record
        }
    )
    (: iterate over the groups - all records in each group have the same values for USUBJID and VISITNUM :)
    for $group in $orderedrecords
        let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $visitnum := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        (: there should be a record in our USUBJID-VISITNUM pairs structure :)
        (: and look up in the SV USUBJID-VISITNUM structure :)
        let $svrecordscount := count($visitnumpairs[@usubjid=$usubjid and @visitnum=$visitnum])
        where $svrecordscount = 0 (: no USUBJID-VISITNUM pair was found in SV :)
        (: iterate over all records in the group for which no USUBJID-VISITNUM pair was found in SV :)
        for $record in $group/odm:ItemGroupData 
            let $recnum := $record/@data:ItemGroupDataSeq
            return <error rule="CG0034" rulelastupdate="2020-06-11" dataset="{data($datasetname)}" variable="VISITNUM" recordnumber="{data($recnum)}">Combination of USUBJID='{data($usubjid)}' and VISITNUM='{data($visitnum)}' in dataset {data($datasetname)} is not found in the SV domain</error>
		
	