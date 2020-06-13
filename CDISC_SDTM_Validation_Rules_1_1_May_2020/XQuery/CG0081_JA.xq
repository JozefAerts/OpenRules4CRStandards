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

(: Rule CG0081 When --PRESP = 'Y' and --OCCUR = null then --STAT = 'NOT DONE'
 Applies to: EVENTS,INTERVENTIONS, NOT(DS, DV, EX) :)
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
(: Applies to: EVENTS,INTERVENTIONS, NOT(DS, DV, EX) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@def:Class='INTERVENTIONS' or @def:Class='EVENTS'][not(@Name='DS') and not(@Name='DV') and not(@Name='EX')]
    let $name := $itemgroupdef/@Name
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: find the OID and name of the --PRESP variable :)
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[OID=$prespoid]/@Name
    (: get the OID and name of the --OCCUR variable :)
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[OID=$occuroid]/@Name
    (: get the OID and name of the --STAT variable :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    (: iterate over all the records with --PRESP = 'Y' and --OCCUR = null  :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$prespoid and @Value='Y'] and not(odm:ItemData[@ItemOID=$occuroid])]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of --STAT :)
    let $stat := $record/odm:ItemData[@ItemOID=$statoid]/@Value
    (: the value of --STAT must be 'NOT DONE' :)
    where not($stat='NOT DONE')
    return <error rule="CG0081" variable="{data($statname)}" dataset="{$name}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-11">Invalid value for {data($statname)}='{data($stat)}' for {data($prespname)}='Y' and {data($occurname)}=null. Value for {data($statname)} expected is 'NOT DONE'</error>				
		
	