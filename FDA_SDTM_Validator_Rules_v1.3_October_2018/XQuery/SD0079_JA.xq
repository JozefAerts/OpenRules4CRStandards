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

(: Rule SD0079: EX record is present, when subject is not assigned to an arm: Subjects that have withdrawn from a trial before assignment to an Arm (ARMCD='NOTASSGN') should not have any Exposure records :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
let $dmdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdataset := concat($base,$dmdatasetname)
(: Get the EX dataset :)
let $exdatasetname := ( 
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='EX']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='EX']/def:leaf/@xlink:href
)
let $exdataset := concat($base,$exdatasetname)
(: get the OID for the ARMCD variable in the DM dataset :)
(: TODO - change this, supposing there is only one is not always correct :)
(: let $armcdoid := $definedoc//odm:ItemDef[@Name='ARMCD']/@OID :)  (: supposing there is only one :) 
let $armcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of USUBJID :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: we also need the OID of the USUBJID in the EX dataset :)
let $exusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='EX']/odm:ItemRef/@ItemOID
    return $a
)
(: in the DM dataset, select the subjects which have ARMCD='NOTASSGN' :)
for $rec in doc($dmdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid and @Value='NOTASSGN']]
    let $usubjidvalue := $rec/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: and the record number for which ARMCD='NOTASSGN' :)
    let $recnum := $rec/@data:ItemGroupDataSeq
    (: and now check whether there is a record in the EX dataset :)
    let $count := count(doc($exdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$exusubjidoid]])
    where $count > 0  (: at least one EX record was found :)
    return <warning rule="SD0079" dataset="EX" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">{data($count)} EX records were found in EX dataset {data($exdatasetname)} for USUBJID={data($usubjidvalue)} although subject has not been assigned to an arm (ARMCD='NOTASSGN') in DM dataset {data($dmdatasetname)}</warning>
