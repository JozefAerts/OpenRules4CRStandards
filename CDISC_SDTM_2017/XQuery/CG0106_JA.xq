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

(: Rule CG0106 - When --TRTV = null then --VAMT = null
Applies to INTERVENTIONS domains :)
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
(: Iterate over the INTERVENTIONS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@def:Class='INTERVENTIONS']
    let $name := $itemgroupdef/@Name
    (: get the OID and Name of --TRTV :)
    let $trtvoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TRTV')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $trtvname := $definedoc//odm:ItemDef[@OID=$trtvoid]/@Name
    (: get the OID and Name of --VAMT :)
    let $vamtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'VAMT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $vamtname := $definedoc//odm:ItemDef[@OID=$vamtoid]/@Name
    (: get the dataset location and make it a document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset for which --TRTV is null (i.e. absent in Dataset-XML) :)
    for $record in $datasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$trtvoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and check whether there is a datapoint for --VAMT :)
        let $vamt := $record/odm:ItemData[@ItemOID=$vamtoid]/@Value
        (: give an error when there is a --VAMT value :)
        where $vamt and $vamt!=''
        return
        <error rule="CG0106" dataset="{data($name)}" variable="{data($vamtname)}" recordnumber="{data($recnum)}" rulelastupdate="2017-02-11">{data($name)}={data($vamt)} but was expected to be null as {data($trtvname)} is null</error>
		
		