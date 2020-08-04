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

(: Rule CG0554: "STUDYID, DOMAIN, and --SEQ exist and at least one of USUBJID, APID, SPDEVID, or POOLID" 
Single dataset version :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the INTERVENTIONS, EVENTS and FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
	let $name := $itemgroupdef/@Name
    let $domainname := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($itemgroupdef/@Name,1,2)
    )
    (: get the OIDs of STUDYID, DOMAIN, and --SEQ :)
    let $studyidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='STUDYID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
   	let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $seqoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SEQ') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $seqname :=  $definedoc//odm:ItemDef[@OID=$seqoid]/@Name
    (: Get the OID (when present) of USUBJID, APID, SPDEVID, POOLID  :)
    let $usubjidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $apidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='APID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $spdevidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='SPDEVID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $poolidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: Give an error when STUDYID, DOMAIN and --SEQ are present, 
    but none of USUBJID, APID, SPDEVID, POOLID is present :)
    where $studyidoid and $domainoid and $seqoid 
    	and not($usubjidoid or $apidoid or $spdevidoid or $poolidoid) 
    return <error rule="CG0554" dataset="{data($name)}" rulelastupdate="2020-08-04">None of USUBJID, APID, SPDEVID, POOLID are present although STUDYID, DOMAIN and {data($seqname)} are present</error> 	
	
	