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

(: Rule SD1251 - When EXTRTV = null then EXVAMTU = null :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the EX datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='INTERVENTIONS']
    let $name := $itemgroupdef/@Name
    (: get the OID of EXTRTV :)
    let $extrtvoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EXTRTV']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the OID of EXVAMTU :)
    let $exvamutoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'EXVAMTU')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and make it a document :)
	let $datasetlocation := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset for which EXTRTV is null (i.e. absent in Dataset-XML) :)
    for $record in $datasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$extrtvoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and check whether there is a datapoint for EXVAMTU :)
        let $exvamtu := $record/odm:ItemData[@ItemOID=$exvamutoid]/@Value
        (: give an error when there is a EXVAMTU value :)
        where $exvamtu and $exvamtu!=''
        return
        <error rule="SD1251" dataset="{data($name)}" variable="EXVAMTU" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08">EXVAMTU={data($exvamtu)} but was expected to be null as EXTRTV is null</error>			
		
	