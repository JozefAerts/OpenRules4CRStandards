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

(: Rule CG0132 - When SS.SSSTRESC = 'DEAD' then DTHFL = 'Y' :)
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
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: Get the SS (Subject Status) dataset and its location :)
let $ssitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SS']
let $ssdatasetlocation := $ssitemgroupdef/def:leaf/@xlink:href
let $ssdatasetdoc := doc(concat($base,$ssdatasetlocation))
(: we need the OID of SSSTRESC and USUBJID in SS :)
let $ssstrescoid := (
    for $a in $definedoc//odm:ItemDef[@Name='SSSTRESC']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $ssusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and we need the OID of USUBJID and of DTHFL in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
) 
let $dthfloid := (
    for $a in $definedoc//odm:ItemDef[@Name='DTHFL']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
) 
(: iterate over all records in SS for which SSSTRESC='DEAD' :)
for $record in $ssdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ssstrescoid and @Value='DEAD']]
    let $recnumss := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID for this record :)
    let $ssusubjid := $record/odm:ItemData[@ItemOID=$ssusubjidoid]/@Value
    (: get the value of DTHFL for this subject in DM :)
    let $dthfl := $dmdatasetdoc//odm:ItemGroupData[@ItemOID=$dmusubjidoid and @Value=$ssusubjid]/odm:ItemData[@ItemOID=$dthfloid]/@Value
    (: the value of DTHFL must be 'Y' :)
    where not($dthfl='Y')
    return <error rule="CG0132" variable="DTHFL" dataset="DM" rulelastupdate="2017-02-18">A record (record number={data($recnumss)}) for USUBJID='{data($ssusubjid)}' has been found for which SSSTRESC='DEAD' but the value of DTHFL='{data($dthfl)}' in DM is not 'Y'</error>			
		
		