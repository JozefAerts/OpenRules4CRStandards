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

(: Rule SD0038 - Value of Study Day variable equals 0
Study Day variables (*DY) value should not equal 0
:)
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
(: iterate over all the datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' 
		or upper-case(@def:Class)='FINDINGS' or @Domain='SE' or @Domain='SV' or @Domain='DM']
    let $name := $dataset/@Name
    let $dsname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$dsname)
    (: for this dataset, find all *DY variables - attention, there can be more than one :)
    let $dyvaroids := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DY')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
    return $a
    )
    (: iterate over all records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over all *DY variables :)
        for $dyvaroid in $dyvaroids
            let $dyname := $definedoc//odm:ItemDef[@OID=$dyvaroid]/@Name
            let $dyvalue := $record/odm:ItemData[@ItemOID=$dyvaroid]/@Value
            (: and check whether it is 0 :)
            where number($dyvalue) = 0
            (: and give out a warning :)
            return <warning rule="SD0038" dataset="{data($name)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Value of Study Day {data($dyname)} variable equals 0</warning>	
