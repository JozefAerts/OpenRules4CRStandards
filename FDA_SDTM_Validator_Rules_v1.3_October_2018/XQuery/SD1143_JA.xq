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

(: Rule SD1143: No Details info for AESMIE Adverse Event in SUPPAE domain :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the AE dataset definition :)
let $aedatasetdef := $definedoc//odm:ItemGroupDef[@Name='AE'] (: we assume there is only one AE dataset :)
(: get its location and the document itself :)
let $aedatasetloc := (
	if($defineversion = '2.1') then $aedatasetdef/def21:leaf/@xlink:href
	else $aedatasetdef/def:leaf/@xlink:href
)
let $aedatasetdoc := doc(concat($base,$aedatasetloc))
(: get the OID of AESMIE :)
let $aesmieoid := (
    for $a in $definedoc//odm:ItemDef[@Name='AESMIE']/@OID 
            where $a = $aedatasetdoc/odm:ItemRef/@ItemOID
        return $a
)
(: and the OID of USUBJID and AESEQ, as we assume that this will be the identifier in SUPPAE :)
(: get the SUPPAE dataset location and document :)
let $aeusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
            where $a = $aedatasetdoc/odm:ItemRef/@ItemOID
        return $a
)
let $aeaeseqoid := (
    for $a in $definedoc//odm:ItemDef[@Name='AESEQ']/@OID 
            where $a = $aedatasetdoc/odm:ItemRef/@ItemOID
        return $a
)
let $suppaedataset := $definedoc//odm:ItemGroupDef[@Name='SUPPAE']
let $suppaedatasetloc := (
	if($defineversion = '2.1') then $suppaedataset/def21:leaf/@xlink:href
	else $suppaedataset/def:leaf/@xlink:href
)
let $suppaedatasetdoc := doc(concat($base,$suppaedatasetloc))
(: we need the OIDs of USUBJID, RDOMAIN, IDVAR, IDVARVAL, QNAM and QVAL :)
let $suppaeusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
let $suppaerdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
let $suppaeidvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
let $suppaeidvarvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
let $suppaeqnamoid := (
    for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
let $suppaeqvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='VAL']/@OID 
            where $a = $suppaedataset/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in AE that have AESMIE populated :)
for $record in $aedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$aesmieoid]/@Value]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the values of USUBJID and AESEQ :)
    let $aeusubjid := $record/odm:ItemData[@ItemOID=$aeusubjidoid]/@Value
    let $aeaeseq := $record/odm:ItemData[@ItemOID=$aeaeseqoid]/@Value
    (: now count the number of records in SUPPAE for which USUBJID and AESEQ match,
    and having the standard supplemental qualifier name (AEVAR) code AESOSP, and IDVARVAL populated :)
    let $count := count($suppaedatasetdoc//odm:ItemGroupData[odm:ItemData[ItemOID=$suppaeusubjidoid]/@Value=$aeusubjid and odm:ItemData[ItemOID=$suppaeidvarvaloid]/@Value=$aeaeseq and odm:ItemData[ItemOID=$suppaerdomainoid]/@Value='AE' and odm:ItemData[ItemOID=$suppaeidvaroid]/@Value='AESEQ' and odm:ItemData[ItemOID=$suppaeidvaroid]/@Value='AESOSP' and odm:ItemData[ItemOID=$suppaeidvarvaloid]/@Value])
    (: there must be one such record :)
    where $count = 0
    return <warning rule="SD1143" dataset="AE" variable="AESMIE" rulelastupdate="2020-08-08" recordnumber="{$recnum}">No record with IDVAR=AESOSP could be found in SUPPAE or SUPPAE is missing</warning> 

