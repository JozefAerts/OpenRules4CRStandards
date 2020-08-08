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
	
(: Rule SD1255 - When AE.AESDTH = 'Y' then DTHFL = 'Y' :)
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
(: Get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location of the DM dataset :)
let $dmdatasetlocation := (
	if($defineversion = '2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: Get the AE (Adverse Events) dataset and its location :)
let $aeitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='AE']
let $aedatasetlocation := (
	if($defineversion = '2.1') then $aeitemgroupdef/def21:leaf/@xlink:href
	else $aeitemgroupdef/def:leaf/@xlink:href
)
let $aedatasetdoc := doc(concat($base,$aedatasetlocation))
(: get the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
) 
(: get the OID of DTHFL in DM :)
let $dthfloid := (
    for $a in $definedoc//odm:ItemDef[@Name='DTHFL']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
) 
(: get the OID of USUBJID in AE :)
let $aeusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $aeitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of AESDTH in AE :)
let $aesdthoid := (
    for $a in $definedoc//odm:ItemDef[@Name='AESDTH']/@OID 
    where $a = $aeitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in AE for which AESDTH='Y' :)
    for $record in $aedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$aesdthoid and @Value='Y']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of USUBJID for this record in AE :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$aeusubjidoid]/@Value
        (: and get the value of DTHFL in DM :)
        let $dthfl := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]]/odm:ItemData[@ItemOID=$dthfloid]/@Value
        (: DTHFL must be 'Y' :)
        where not($dthfl='Y')
        return <error rule="SD1255" variable="DTHFL" dataset="DM" rulelastupdate="2020-08-08">A record for USUBJID='{data($usubjid)}' (record number {data($recnum)}) has been found in the AE dataset with AESDTH='Y' but the value of DTHFL='{data($dthfl)}' in DM is not 'Y'</error>				
		
	