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

(: Rule SD0065: USUBJID/VISIT/VISITNUM values do not match SV domain data - 
All Unique Subject Identifier (USUBJID) + Visit Name (VISIT) + Visit Number (VISITNUM) combination values in data should be present in the Subject Visits (SV) domain. There is an exception for records, where Status (--STAT) variable value is populated. E.g., --STAT = 'NOT DONE' :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml'  :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SV dataset definition :)
let $svdatasetdef := $definedoc//odm:ItemGroupDef[@Name='SV']
(: and the OIDs of USUBJID, VISIT and VISITNUM :)
let $svusubjudoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
            where $a = $svdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $svvisitoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
            where $a = $svdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $svvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
            where $a = $svdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
(: and the location of the SV dataset :)
 let $svdatasetloc := (
	if($defineversion = '2.1') then $svdatasetdef/def21:leaf/@xlink:href
	else $svdatasetdef/def:leaf/@xlink:href
)
 let $svdatasetdoc := doc(concat($base,$svdatasetloc))
(: create a temporary structure containing triples USUBJID-VISITNUM-VISIT from SV :)
let $svtriples := (
    for $record in $svdatasetdoc//odm:ItemGroupData
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$svusubjudoid]/@Value
        let $visitvalue := $record/odm:ItemData[@ItemOID=$svvisitoid]/@Value
        let $visitnumvalue := $record/odm:ItemData[@ItemOID=$svvisitnumoid]/@Value
        return <svrecord usubjid="{$usubjidvalue}" visit="{$visitvalue}" visitnum="{$visitnumvalue}" />
)
(: return <test>{$svtriples}</test> :)
(: iterate over all other datasets except for SV :)
for $datasetdef in $definedoc//odm:ItemGroupDef[not(@Name='SV')]
    (: get the dataset name :)
    let $name := $datasetdef/@Name
    (: also here, we need the OIDs of USUBJID, VISIT and VISITNUM . these can be different from those in SV :)
    let $usubjudoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $visitoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
                where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
                where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
	(: and, not to forget, the OID of the --STAT variable  :)
	let $statoid := (
		for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
                where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
	)
    (: get the location of the dataset :)
    let $datasetloc := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the document itself :)
    let $datasetdoc := doc(concat($base,$datasetloc))
    (: iterate over all the records in the dataset, 
    but only if USUBJID, VISIT and VISITNUM have been defined for the dataset, 
    AND there is a value for all three of them :)
    for $record in $datasetdoc[$usubjudoid and $visitoid and $visitnumoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjudoid]/@Value and odm:ItemData[@ItemOID=$visitoid]/@Value and odm:ItemData[@ItemOID=$visitnumoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of USUBJID, VISIT and VISITNUM :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjudoid]/@Value
        let $visitvalue := $record/odm:ItemData[@ItemOID=$visitoid]/@Value
        let $visitnumvalue := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
		let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        (: this triple must also appear in the list of triples :)
        let $count := count($svtriples[@usubjid=$usubjidvalue and @visit=$visitvalue and @visitnum=$visitnumvalue])
        (: there must be at least one such record in SV, except for when --STAT is populated :)
        where $count = 0 and not($statvalue)
        return <warning rule="SD0065" dataset="{$name}" variable="VISIT" rulelastupdate="2020-08-08" recordnumber="{$recnum}">The value of USUBJID='{data($usubjidvalue)}', VISIT='{data($visitvalue)}', VISITNUM='{data($visitnumvalue)}' in dataset '{data($name)}' could not be found in the SV dataset </warning> 

