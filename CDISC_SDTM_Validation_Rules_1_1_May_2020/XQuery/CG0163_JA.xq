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

(: CO: Comment related to Domain Records and RDOMAIN not in (null, 'DM'), then IDVAR ^= null 
P.S. This rule is not applicable in the case that the comment is a general comment for the complete domain. 
This can however not be checked, as the presence of IDVAR is an INDICATOR that this is not the case. 
So, strictly spoken, the rule would never be implementable :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the CO dataset :)
let $coitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='CO']
let $codatasetlocation := (
	if($defineversion='2.1') then $coitemgroupdef/def21:leaf/@xlink:href
	else $coitemgroupdef/def:leaf/@xlink:href
)
let $codatasetdoc := (
	if($codatasetlocation) then doc(concat($base,$codatasetlocation))
	else ()
)
(: get the OIDs of the RDOMAIN and IDVAR variables :)
let $rdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $idvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $definedoc := doc(concat($base,$define))
(: get the CO dataset :)
let $coitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='CO']
(: get the OIDs of the RDOMAIN and IDVAR variables :)
let $rdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
let $idvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
    where $a = $coitemgroupdef/odm:ItemRef/@ItemOID
    return $a 
)
(: get the CO dataset when there is one :)
let $codatasetlocation := (
	if($defineversion='2.1') then $coitemgroupdef/def21:leaf/@xlink:href
	else $coitemgroupdef/def:leaf/@xlink:href
)
let $codatasetdoc := doc(concat($base,$codatasetlocation))[$rdomainoid]
(: iterate over all records in the CO dataset :)
for $record in $codatasetdoc[$rdomainoid and $idvaroid]//odm:ItemGroupData
	let $recnum := $record/@data:ItemGroupDataSeq  (: record number :)
    (: get the value of RDOMAIN and of IDVAR :)
    let $rdomain := $record/odm:ItemGroupData[@ItemOID=$rdomainoid]/@Value
    let $idvar := $record/odm:ItemGroupData[@ItemOID=$idvaroid]/@Value
    (: when RDOMAIN is not null and not 'DM', IDVAR may not be null, 
    second part takes care that a warning is thrown when IDVAR is absent. 
	We set it to WARNING as the comment may still be a general comment for the whole domain :)
    where (not($rdomain='DM') and $rdomain) and $idvar
    return <warning rule="CG0163" dataset="CO" variable="IDVAR" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">IDVAR must be null, value '{data($idvar)}' was found, as value for RDOMAIN is null or 'DM'</warning>
	
	