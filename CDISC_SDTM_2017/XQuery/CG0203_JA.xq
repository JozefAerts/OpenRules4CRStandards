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

(: Rule CG0203 - SUPPxx - When RDOMAIN != 'DM' then IDVAR != null :)
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
(: iterate over all the SUPPxx dataset definitions :)
for $suppitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $suppitemgroupdef/@Name
    (: get the dataset location :)
    let $suppdatasetlocation := $suppitemgroupdef/def:leaf/@xlink:href
    let $suppdatasetdoc := doc(concat($base,$suppdatasetlocation))
    (: we need the OID of RDOMAIN and of IDVAR :)
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
        where $a = $suppitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $suppitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records for which RDOMAIN != 'DM' :)
    for $record in $suppdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rdomainoid and not(@Value='DM')]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of IDVAR (if any) :)
        let $idvar := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
        (: and of RDOMAIN :)
        let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        (: IDVAR must be != null :)
        where not($idvar)  (: IDVAR is null :)
        return <error rule="CG0203" dataset="{data($name)}" variable="IDVAR" recordnumber="{data($recnum)}" rulelastupdate="2017-02-23" >IDVAR is not allowed to be null when RDOMAIN='{data($rdomain)}' is different from 'DM'</error>			
		
		