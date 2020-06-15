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

(: Rule CG0201 - RELREC - When IDVARVAL = null and USUBJID = null then IDVAR  != --SEQ :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the RELREC dataset definition :)
let $relrecitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='RELREC']
(: get the dataset location :)
let $relrecdatasetlocation := $relrecitemgroupdef/def:leaf/@xlink:href
let $relrecdatasetdoc := (
	if($relrecdatasetlocation) then doc(concat($base,$relrecdatasetlocation))
	else ()
)
(: get the OID of USUBJID, IDVAR and IDVARVAL :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $idvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $idvarvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the dataset for which IDVARVAL = null and USUBJID = null :)
for $record in $relrecdatasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$idvarvaloid]) and not(odm:ItemData[@ItemOID=$usubjidoid])]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of IDVAR :)
    let $idvar := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
    (: IDVAR is not allowed to be --SEQ :)
    where not(ends-with($idvar,'SEQ') and string-length($idvar)=5)
    return <error rule="CG0201" dataset="RELREC" variable="IDVAR" recordnumber="{data($recnum)}" rulelastupdate="2020-06-15" >IDVAR={data($idvar)} is not allowed as USUBJID=null and IDVARVAL=null</error>			
		
	