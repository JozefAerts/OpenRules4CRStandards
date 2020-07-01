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
	
(: Rule SD1042- Time point for non-occurred event or intervation is provided: 
Value of Start Relative to Reference Period (--STRF) or End Relative to Reference Period (--ENRF) should not be populated, when an event or intervention is marked as not occurred (--OCCUR='N')
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all the provided datasets, but only the INTERVENTIONS and EVENTS ones :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS']
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: Get the OID of the ENRF and OCCUR variables :)
    let $enrfoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENRF')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrfname := concat($name,'ENRF')
    let $occuroid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := doc(concat($base,$define))//odm:ItemDef[@OID=$occuroid]/@Name
    (: iterate over all the records that have an --OCCUR data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$occuroid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $occurvalue := $record/odm:ItemData[@ItemOID=$occuroid]/@Value
        (: check whether ENRF are populated - if so, get the value :)
        let $enrfvalue := $record/odm:ItemData[@ItemOID=$enrfoid]/@Value
        (: ENRF may NOT be present when OCCUR is present :)
        where $occurvalue and $enrfvalue
        return <warning rule="SD1042-B" dataset="{data($name)}" variable="{data($enrfname)}" rulelastupdate="2019-09-03" recordnumber="{data($recnum)}">Value of End Relative to Reference Period ({data($enrfname)} should not be populated for non-occurred event or intervation is provided, with value of {data($occurname)}={data($occurvalue)}</warning>	
