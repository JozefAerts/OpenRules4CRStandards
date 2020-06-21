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

(: Rule CG0401 - When --PRESP = 'Y' and  --OCCUR = null then --STAT present in dataset
All EVENTS and INTERVENTIONS domains, except for AE, DS, DV, EX :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all EVENTS and INTERVENTIONS studies, except for AE, DS, DV, EX :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='INTERVENTIONS'][not(starts-with(@Name,'AE') or starts-with(@Name,'DS') or starts-with(@Name,'DV') or starts-with(@Name,'EX'))]
    let $name := $itemgroupdef/@Name
    (: get the OIDs of --PRESP, --OCCUR and --STAT (when present)  - also get the name :)
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[@OID=$prespoid]/@Name
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[@OID=$occuroid]/@Name
     let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := concat(substring($name,1,2),'STAT')  (: we need a name, even when the --STAT variable is not defined :)
    (: get the dataset location and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: count the number of records for which --PRESP = 'Y' and  --OCCUR = null - 
    if there is at least one, --STAT must be present (i.e. defined) - 
    but only when --PRESP and --OCCUR are defined for the dataset :)
    let $count := count($datasetdoc[$prespoid and $occuroid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$prespoid]/@Value='Y' and not(odm:ItemData[@ItemOID=$occuroid])])
    (: when there is at least such a record, --STAT must be present :)
    where $count>0 and not($statoid)
    return <error rule="CG0404" dataset="{data($name)}" variable="{data($statname)}" rulelastupdate="2020-06-18">{data($statname)} is not present in dataset, although there are records with {data($prespname)} = 'Y' and  {data($occurname)} = null</error>									
		
	