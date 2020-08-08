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

(: Rule SD1317: DSSTDTC for DEATH record is not the same as DM.DTHDTC - DEATH records (DSDECOD='DEATH') in Disposition (DS) domain should have Start Date of Event (DSDTDTC) equals to subject's Date/Time of Death (DTHDTC) populated in Demographics (DM) domain. Subject's Date/Time of Death info should be consistent across all domain. :)
(: ONLY applies DS :)
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
let $definedoc := doc(concat($base,$define))
(: get the DM dataset :)
let $dmdatasetdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location and the document itself :)
let $dmdatasetloc := (
	if($defineversion = '2.1') then $dmdatasetdef/def21:leaf/@xlink:href
	else $dmdatasetdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetloc))
(:  get the OIDs of USUBJID and DTHDTC in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $dmdthdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DTHDTC']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
(: now create a temporary structure containing the DM USUBJID-DTHDTC pairs :)
let $dthdtcpairs := (
    for $record in $dmdatasetdoc//odm:ItemGroupData
        let $dmusubjid := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
        let $dthdtc := $record/odm:ItemData[@ItemOID=$dmdthdtcoid]/@Value
        return <dthdtcpair usubjid="{data($dmusubjid)}" dthdtc="{data($dthdtc)}" />
)
(: get the DS dataset(s) :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='DS' or @Domain='DS']
    let $name := $datasetdef/@Name
    (: get the location and the dataset document itself :)
    let $datasetloc := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetloc))
    (: get the OID of USUBJID, DSDECOD, DSDTDTC :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $dsdecodoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $dsstdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records that for which DSDECOD='DEATH' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsdecodoid and @Value='DEATH']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of USUBJID and DSDTDTC :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $dsstdtc := $record/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
        (: and look them up in the DM-USUBJID- structure, 
        retrieving the value for DTHDTC for the given subject :)
        let $dthdtc := $dthdtcpairs[@usubjid=$usubjid]/@dthdtc
        (: DTHDTC from DM and DSSTDTC from DS must be equal :)
        where not($dsstdtc = $dthdtc) 
        return <error rule="SD1317" dataset="{data($name)}" variable="DSSTDTC" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">DSSTDTC value '{data($dsstdtc)}' does not correspond to DM.DTHDTC='{data($dthdtc)}' for USUBJID={data($usubjid)}  </error>		
	
	