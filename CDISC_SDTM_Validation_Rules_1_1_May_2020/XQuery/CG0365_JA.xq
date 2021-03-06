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

(: Rule CG0365 - When RSUBJID != null then RDEVID = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all AP datasets :)
for $apitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'AP')]
    let $name := $apitemgroupdef/@Name
    (: and get the OID of the RDEVID and of RSUBJID variable (if any) :)
    let $rdevidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDEVID']/@OID 
        where $a = $apitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $rsubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RSUBJID']/@OID 
        where $a = $apitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location and document for the RELSUB dataset :)
	let $apdatasetlocation := (
		if($defineversion='2.1') then $apitemgroupdef/def21:leaf/@xlink:href
		else $apitemgroupdef/def:leaf/@xlink:href
	)
    let $apdoc := doc(concat($base,$apdatasetlocation))
    (: iterate over all the records for which RSUBJID != null :)
    for $record in $apdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rsubjidoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of RSUBJID and of RDEVID (if any) :)
        let $rdevid := $record/odm:ItemData[@ItemOID=$rdevidoid]/@Value
        let $rsubjid := $record/odm:ItemData[@ItemOID=$rsubjidoid]/@Value
        (: RDEVID must be null :)
        where $rdevid
        return <error rule="CG0365" dataset="{data($name)}" variable="RDEVID" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">RDEVID='{data($rdevid)}' must be null as RSUBJID='{data($rsubjid)}' is not null</error>						
		
	