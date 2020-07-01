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

(: Rule SD2024 - Missing or redundant values for USUBJID and POOLID:
 Either Unique Subject Identifier (Missing or redundant values for USUBJID and POOLIDUSUBJID) or Pool Identifier (POOLID) variables values and only one must be populated :)
xquery version "3.0";
(: POOLID is e.g. used in RELREC :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml'  :)
(: EITHER provide $domain=:'ALL', meaning: validate for all domains referenced from the define.xml OR:
$domain:='XX' where XX is a specific domain, MEANING validate for a single domain only :)
(:  get the definitions for the domains (ItemGroupDefs in define.xml) :)
(:  let $datasets := (
    if($domain != 'ALL') then doc(concat($base,$define))//odm:ItemGroupDef[@Domain=$domain]
    else doc(concat($base,$define))//odm:ItemGroupDef
) :)
(: now iterate over all dataset definitions in the define.xm and get the USUBJID :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS']
    let $name := $itemgroupdef/@Name
    let $datasetlink := $itemgroupdef/def:leaf/@xlink:href
    let $datasetpath := concat($base,$datasetlink)
    (: get the OID of the POOLID and the USUBJID variables :)
    let $poolidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    ) 
    let $usubjidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    ) 
    (: iterate over all the records, but only when USUBJID and POOLID have been defined :)
    for $record in doc($datasetpath)[$usubjidoid and $poolidoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of POOLID and USUBJID (if any) :)
        let $poolid := $record/odm:ItemData[@ItemOID=$poolidoid]/@Value
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
		
		let $message := (
		    (: case that both USUBJID AND POOLID are populated :)
            if(string-length($poolid) > 0 and string-length($usubjid) > 0) then
                <error rule="SD2024"  dataset="{$name}"  rulelastupdate="2019-08-30" recordnumber="{data($recnum)}">Both USUBJID and POOLID in dataset {data($name)} are populated</error>
            (: case that neither USUBJID nor POOLID are populated :)
            else if (not($usubjid) and not($poolid)) then
                <error rule="SD2024"  dataset="{$name}"  rulelastupdate="2019-08-30" recordnumber="{data($recnum)}">Both USUBJID and POOLID in dataset {data($name)} are populated</error>
            else ()
		)
		(: return the dynamically generated message (which can be null)  :)
        return $message  

