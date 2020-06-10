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

(: Rule CG0069: When DSDECOD = 'DEATH' then DSSTDTC = DM.DTHDTC :)
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
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the DS dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Get the DM dataset and its location :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of USUBJID and of DSDECOD in DS :)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of DSSTDTC :)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of USUBJID and of DTHDTC in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dmdthdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DTHDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: Iterate over all records that have DSDECOD='DEATH' :)
for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsdecodoid and @Value='DEATH']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the USUBJID :)
    let $usubjid := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
    (: and the value of DSSTDTC :)
    let $dsstdtc := $record/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
    (: find that record in the DM dataset :)
    let $dmrecord := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]]
    (: get the value of DTHDTC :)
    let $dthdtc :=  $dmrecord/odm:ItemData[@ItemOID=$dmdthdtcoid]/@Value
    (: DSSTDTC and DTHDTC must be equal :)
    where not($dsstdtc = $dthdtc)
    return <error rule="CG0069" variable="DSSTDTC" dataset="DS" rulelastupdate="2017-02-08">A record (record number={data($recnum)}) for USUBJID='{data($usubjid)}' has been found for which DSDECOD='DEATH' but the value of DSSTDTC={data($dsstdtc)} does not correspond to DTHDTC={data($dthdtc)} in DM</error>			
		