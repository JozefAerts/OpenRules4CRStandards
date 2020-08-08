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
	
(: TODO: test on large submission with more splitted datasets :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
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
(: find all subjects in DM for which ARMCD is NOT SCRNFAIL, NOT NOTASSGN and NOT NOTTRT :)
let $randomizedsubjects := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid][not(@Value='SCRNFAIL') and not(@Value='NOTASSGN') and not(@Value=NOTTRT)]]/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
(: iterate over all applicable DOMAINS, taking splitted datasets into account :)
let $domains := ('EG','LB','MB','MS','PC','VS')
(: there can be more than 1 dataset per domain :)
for $domain in $domains
    let $datasets := $definedoc//odm:ItemGroupDef[@Domain=$domain or starts-with(@Name,$domain)] (: provides a list of nodes :)
    let $datasetslocationsindomain := (
		if($defineversion = '2.1') then (concat($base,$definedoc//odm:ItemGroupDef[@Domain=$domain]/def21:leaf/@xlink:href))
		else (concat($base,$definedoc//odm:ItemGroupDef[@Domain=$domain]/def:leaf/@xlink:href))
	)
    (: get the name of the BLFL variable :)
    let $blflname := concat($domain,'BLFL') 
    (: and the OID - should be the same for each of the datasets within the single domain :)
    let $blfloid := $definedoc//odm:ItemDef[@Name=$blflname]/@OID
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Domain=$domain][1]/odm:ItemRef/@ItemOID
        return $a
    )
    (: return <test>{data($domain)} - {data($blfloid)}</test> :)
    (: iterate over all the randomized subjects and count the number of baseline flag records 
    over all the datasets within that domain :)
    for $subject in $randomizedsubjects
        let $count := count( 
            for $dataset in $datasetslocationsindomain
                let $c := doc($dataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid][@Value=$subject] and odm:ItemData[@ItemOID=$blfloid]]/@data:ItemGroupDataSeq
                return $c
        )  
        (: $count gives the number of records with a baseline flag for the subject :)
        where count($datasets) > 0 and $count = 0   (: no baseline record for this subject found in any of the datasets in this domain :)
        return <warning rule="SD0006" dataset="{data($domain)}" variable="{data($blflname)}" rulelastupdate="2020-08-08">No baseline result in Domain {data($domain)} for subject {data($subject)}</warning>
