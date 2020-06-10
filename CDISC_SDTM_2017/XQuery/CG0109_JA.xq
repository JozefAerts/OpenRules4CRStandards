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

(: Rule CG0109 - When no records in EX for Subject then DM.ACTARMCD in ('SCRNFAIL', 'NOTASSGN', 'NOTTRT')  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the OID of ACTARMCD in DM :)
let $actarmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the EX dataset - we assume there is only one :)
let $exitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='EX']
let $exdatasetlocation := $exitemgroupdef/def:leaf/@xlink:href
let $exdatasetdoc := doc(concat($base,$exdatasetlocation))
(: get the OID of USUBJID in EX - this can be different from the one in DM :)
let $exusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $exitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records in the DM dataset :)
for $record in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID and the value of ACTARMCD :)
    let $actarmcd := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
    let $usubjid :=  $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    (: count the records for this subject in EX :)
    let $excount := count($exdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$exusubjidoid and @Value=$usubjid]])
    (: when the count is 0 (no records for this subject in EX),
    then ACTARMCD must be in ('SCRNFAIL', 'NOTASSGN', 'NOTTRT' :)
    where $excount=0 and not($actarmcd='SCRNFAIL' or $actarmcd='NOTASSGN' or $actarmcd='NOTTRT')
    return
        <error rule="CG0109" dataset="DM" variable="ACTARMCD" recordnumber="{data($recnum)}" rulelastupdate="2017-02-11">No records were found for USUBJID={data($usubjid)} in EX but ACTARMCD is not one of 'SCRNFAIL', 'NOTASSGN', 'NOTTRT'. The value found for ARCTARMCD='{data($actarmcd)}'</error>			
		
		