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

(: Rule CG0423 - When --VAMT != null then --TRTV != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all INTERVENTIONS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS']
    let $name := $itemgroupdef/@Name
    (: get the dataset location and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the --VAMT and --TRTV variable :)
    let $vamtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'VAMT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $vamtname := $definedoc//odm:ItemDef[@OID=$vamtoid]/@Name
    let $trtvoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TRTV')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $trtvname := doc(concat($base,$define))//odm:ItemDef[@OID=$trtvoid]/@Name
    (: iterate over all records in the dataset for which --VAMT is populated (not null),
    at least when --VAMT and --TRTV have been defined :)
    for $record in $datasetdoc[$vamtoid and $trtvoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$vamtoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of --VAMT and of --TRTV (if any) :)
        let $vamt := $record/odm:ItemData[@ItemOID=$vamtoid]/@Value
        let $trtv := $record/odm:ItemData[@ItemOID=$trtvoid]/@Value
        (: When --VAMT != null then --TRTV != null :)
        where $vamt and not($trtv)
        return <error rule="CG0423" dataset="{data($name)}" variable="{data($trtvname)}" rulelastupdate="2019-08-13" recordnumber="{data($recnum)}">{data($trtvname)} may not be NULL, as ({data($vamtname)})='{data($vamt)}' is not null</error>			
		
		