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
	
(: Rule SD0006 - No baseline result in Domain for subject
All subjects should have at least one baseline observation (--BLFL = 'Y') in EG, LB, MB, MS, PC and VS domains, except for subjects who failed screening (ARMCD = 'SCRNFAIL') or were not fully assigned to an Arm (ARMCD = 'NOTASSGN') or were not treated (ACTARMCD = 'NOTTRT') in datasets EG, LB, MB, MS, PC, VS
:)
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
declare variable $datasetname external; 
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'LB' :)
let $definedoc := doc(concat($base,$define))
(: find all subjects in DM for which ARMCD is NOT SCRNFAIL, NOT NOTASSGN and NOT NOTTRT :)
(: we need the OID of ARMCD :)
let $armcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(:  and the OID of the USUBJID variable :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: and the location of the DM dataset :)
let $dmdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdatasetlocation := concat($base,$dmdatasetname)
(: generate a list of all subjects in DM for which ARMCD is NOT SCRNFAIL, NOT NOTASSGN and NOT NOTTRT :)
let $randomizedsubjects := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid][not(@Value='SCRNFAIL') and not(@Value='NOTASSGN') and not(@Value=NOTTRT)]]/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
(: iterate over all applicable DOMAINS, taking splitted datasets into account :)
(: let $domains := ('EG','LB','MB','MS','PC','VS') :)
(: apply to the provided dataset but only if in one of the six applicable domains :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Domain='EG' or @Domain='LB' or @Domain='MB' or @Domain='MS' or @Domain='PC' or @Domain='VS'] (: provides a list of nodes :)
    let $datasetlocation := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href 
		else $dataset/def:leaf/@xlink:href
	)
    (: get the name of the BLFL variable :)
    let $domain := $dataset/@Domain
    let $blflname := concat($domain,'BLFL') 
    (: and the OID of --BLFL and USUBJID - should be the same for each of the datasets within the single domain :)
    let $blfloid := $definedoc//odm:ItemDef[@Name=$blflname]/@OID
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dataset/odm:ItemRef/@ItemOID
        return $a
    )
    (: return <test>{data($domain)} - {data($blfloid)}</test> :)
    (: iterate over all the randomized subjects and count the number of baseline flag records 
    over all the datasets within that domain :)
    for $subject in $randomizedsubjects (: $randomizedsubjects is a list of randomized subjects :)
        (: $count gives the number of records with a baseline flag for the subject :)
        let $count := count(doc(concat($base,$datasetlocation))//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid and @Value=$subject] and odm:ItemData[@ItemOID=$blfloid and @Value='Y']])
        where $count = 0   (: no baseline record for this subject found in any of the datasets in this domain :)
        return <warning rule="SD0006" dataset="{data($datasetname)}" variable="{data($blflname)}" rulelastupdate="2020-08-08">No baseline result in Dataset {data($domain)} for subject {data($subject)} </warning>	
