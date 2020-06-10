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

(: Rule CG0075 DVSTDTC >= DM.RFICDTC :)
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
(: Get the DV dataset :)
let $dvitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DV']
(: and the location of the DS dataset :)
let $dvdatasetlocation := $dvitemgroupdef/def:leaf/@xlink:href
let $dvdatasetdoc := doc(concat($base,$dvdatasetlocation))
(: get DVSTDTC in DS :)
let $dvstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DVSTDTC']/@OID 
    where $a = $dvitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of USUBJID in DV :)
let $dvusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dvitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/xlink:href/@xlink:href
let $dmdatasetdoc := doc($dmdatasetlocation)
(: and the OID of USUBJID and RFICDTC :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dmrficdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFICDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a    
)
(: Iterate over all DVSTDTC records in DV :)
for $record in $dvdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dvstdtcoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the USUBJID :)
    let $usubjid := $record/odm:ItemData[@ItemOID=$dvusubjidoid]/@Value
    (: and get the value of DVSTDTC :)
    let $dvstdtc := $record/odm:ItemData[@ItemOID=$dvstdtcoid]/@Value
    (: find the corresponding record in DM :)
    let $dmrecord := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]]
    (: get the value of RFICDTC :)
    let $rficdtc := $dmrecord/odm:ItemData[@ItemOID=$dmrficdtcoid]/@Value
    (: we can only check the rule when DVSTDTC and RICDTC are valid dates. When so: DVSTDTC >= DM.RFICDTC  :)
    where $dvstdtc castable as xs:date and $dvstdtc castable as xs:date and not(xs:date($dvstdtc) >= xs:date($rficdtc))
    return <error rule="CG0075" dataset="DS" rulelastupdate="2017-02-08" recordnumber="{data($recnum)}">Deviation date DVSTDTC={data($rficdtc)} is after informed consent data RFICDTC={data($dvstdtc)} </error>		
		
		