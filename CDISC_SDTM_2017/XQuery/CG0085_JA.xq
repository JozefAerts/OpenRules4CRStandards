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

(: Rule CG0085: --PRESP in ('Y', null)
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
(: Applies to: EVENTS,INTERVENTIONS, but not to EX, DS, DV :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@def:Class='INTERVENTIONS' or @def:Class='EVENTS' and not(@Name='EX') and not(@Name='DS') and not(@Name='DV')]
    let $name := $itemgroupdef/@Name
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of --PRESP :)
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[@OID=$prespoid]/@Name
    (: iterate over all the dataset records that do have --PRESP and where --PRESP is not null :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$prespoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: the only allowed value for --PRESP is 'Y' as we already skipped the --PRESP=null records :)
        let $presp := $record/odm:ItemData[@ItemOID=$prespoid]/@Value
        where not($presp='Y')
        return
        <error rule="CG0085" rulelastupdate="2017-02-10" dataset="{data($name)}" variable="{data($prespname)}" recordnumber="{data($recnum)}">{data($prespname)} is only allowed to be 'Y' or null, {data($prespname)}='{data($presp)}' was found</error>			
		
		