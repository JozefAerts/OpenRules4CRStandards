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

(: Rule CG0067: When SS.SSSTRESC = 'DEAD', then there must be a record for that subject in DS with DSDECOD='DEATH' :)
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
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the DS dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Get the SS (Subject Status) dataset and its location :)
let $ssitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SS']
let $ssdatasetlocation := $ssitemgroupdef/def:leaf/@xlink:href
let $ssdatasetdoc := doc(concat($base,$ssdatasetlocation))
(: we need the OID of DSDECOD and USUBJID in DS :)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: we need the OID of SSSTRESC and of USUBJID in SS :)
let $ssusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $ssstresc := (
    for $a in $definedoc//odm:ItemDef[@Name='SSSTRESC']/@OID 
    where $a = $ssitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in SS for which SSSTRESC='DEAD' :)
for $record in $ssdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ssstresc and @Value='DEAD']]
    let $recnumss := $record/@data:ItemGroupDataSeq
    (: get the value of USUBJID for this record :)
    let $ssusubjid := $record/odm:ItemData[@ItemOID=$ssusubjidoid]/@Value
    (: there must be at least one record for this subject in DS for which DSDECOD='DEATH' :)
    let $deathdsrecords := $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=ssusubjid] and odm:ItemData[@ItemOID=$dsdecodoid and @Value='DEATH']]
    where count($deathdsrecords) < 1  (: no DS record found for this subject with DSDECOD='DEATH' :)
    return <error rule="CG0067" variable="DSDECOD" dataset="DS" rulelastupdate="2017-02-06">A record (record number={data($recnumss)}) for USUBJID='{data($ssusubjid)}' has been found for which SSSTRESC='DEAD' but no record with DSDECOD='DEATH' was found in dataset DS</error>
	