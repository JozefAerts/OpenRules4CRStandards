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

(: Rule CG0412 - When DM.ACTARMCD not in ('SCRNFAIL', 'NOTASSGN', 'NOTTRT') then Subject records > 0 in DS  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' 
let $definedoc := doc(concat($base,$define)) :)
(: get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of USUBJID and ACTARMCD :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dmactarmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ACTARMCD']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: get the OID of USUBJID in DS (can be different from the one in DM) :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in DM :)
for $record in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID and of ACTARMCD :)
    let $dmusubjid := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
    let $actarmcd := $record/odm:ItemData[@ItemOID=$dmactarmcdoid]/@Value
    (: when ACTARMCD is NOT  'SCRNFAIL', 'NOTASSGN', 'NOTTRT'
    then count the number of records for this subject in DS :)
    let $errormessages := 
    if ($actarmcd != 'SCRNFAIL' and $actarmcd != 'NOTASSGN' and $actarmcd != 'NOTTRT') then
        let $count := count($dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$dmusubjid]])
        where $count = 0
        return <error rule="CG0412" dataset="DS" rulelastupdate="2017-03-22" recordnumber="{data($recnum)}">No records found for USUBJID={data($dmusubjid)} and ACTARMCD='{data($actarmcd)}' in DS</error>			
    else ()  (: ACTARMC is one of 'SCRNFAIL', 'NOTASSGN', 'NOTTRT' - nothing to do :)
    (: 'print' the error messages :)
    return $errormessages			
		
		