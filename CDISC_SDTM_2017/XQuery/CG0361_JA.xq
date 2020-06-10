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

(: Rule CG0361 - RELSUB - When USUBJID != null then POOLID = null:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the RELSUB dataset :)
let $relsubitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='RELSUB']
    (: and get the OID of the USBJID and of POOLID variable (if any) :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $relsubitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $poolidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
        where $a = $relsubitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location and document for the RELSUB dataset :)
    let $relsubdatasetlocation := $relsubitemgroupdef/def:leaf/@xlink:href
    let $relsubdoc := doc(concat($base,$relsubdatasetlocation))
    (: iterate over all the records in the RELSUB for which USUBJID != null :)
    for $record in $relsubdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of USUBJID and of POOLID (if any) :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $poolid := $record/odm:ItemData[@ItemOID=$poolidoid]/@Valu61
        (: POOLID must be null :)
        where $poolid
        return <error rule="CG0361" dataset="RELSUB" variable="POOLID" recordnumber="{data($recnum)}" rulelastupdate="2017-03-15">POOLID='{data($poolid)}' must be null as USUBJID='{data($usubjid)}' is not null</error>		
		
		