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

(: Rule CG0086 - When --PRESP = 'Y' and --STAT = null  and --OCCUR is present in dataset then --OCCUR != null 
Applies to: EVENTS,INTERVENTIONS, NOT(DS, DV, AE) :)
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
(: Applies to: EVENTS,INTERVENTIONS but not to AE, DS, DV :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@def:Class='INTERVENTIONS' or @def:Class='EVENTS' and not(@Name='AE') and not(@Name='DS') and not(@Name='DV')]
    let $name := $itemgroupdef/@Name
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID and name of --PRESP :)
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[@OID=$prespoid]/@Name
    (: get the OID of --STAT :)
     let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    (: get the OID of --OCCUR :)
     let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[@OID=$occuroid]/@Name
    (: iterate over all the records in the dataset but only when --OCCUR is present ,
    and when --PRESP = 'Y' and --STAT = null for that record :)
    for $record in $datasetdoc[$statoid and $occuroid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$prespoid and @Value='Y'] and not(odm:ItemData[@ItemOID=$statoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: When --PRESP = 'Y' and --STAT = null  and --OCCUR is present in dataset then --OCCUR != null :)
        (: --OCCUR may not be null :)
        (: get the value of --OCCUR :)
        let $occur := $record/odm:ItemData[@ItemOID=$occuroid]/@Value
        where not($occur)  (: selects when --OCCUR is null :)
        return
            <error rule="CG0086" rulelastupdate="2017-02-10" dataset="{data($name)}" variable="{data($occurname)}" recordnumber="{data($recnum)}">{data($occurname)}=null for record with {data($prespname)}='Y' and {data($statname)}=null</error>	
		
		