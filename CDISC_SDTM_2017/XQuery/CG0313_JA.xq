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

(: Rule CG0313 - STUDYID, USUBJID or POOLID, DOMAIN, and --SEQ exist - applicable to domains of the general observation classes:
INTERVENTIONS, FINDINGS, EVENTS :)
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
(: iterate over all datasets definitions of the general observation classes:
INTERVENTIONS, FINDINGS, EVENTS :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@def:Class='INTERVENTIONS' or @def:Class='FINDINGS' or @def:Class='EVENTS']
    let $name := $itemgroupdef/@Name
    (: get the OID of the variables STUDYID, USUBJID, POOLID, DOMAIN and --SEQ :)
    let $studyidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='STUDYID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $poolidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $seqoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SEQ')]/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: test the presence :)
    (: TODO: can we test separately for each? :)
    where not($studyidoid) or (not($usubjidoid) and not($poolidoid)) or not($domainoid) or not($seqoid)
    return <error rule="CG0313" dataset="{data($name)}" rulelastupdate="2017-03-06">One of the required identifier variables STUDYID, USUBJID/POOLID, DOMAIN, or --SEQ is missing</error>							
		
		