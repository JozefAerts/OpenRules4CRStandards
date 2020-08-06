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
	
(: Rule SD1042-A Time point for non-occurred event or intervation is provided: 
Value of Start Relative to Reference Period (--STRF) should not be populated, when an event or intervention is marked as not occurred (--OCCUR='N')
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
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets , but only the provided INTERVENTIONS and EVENTS ones :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS'
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS']
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($dsname) then doc(concat($base,$dsname))
		else ()
	)
    (: Get the OID of the STRF and OCCUR variables :)
    let $strfoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRF')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strfname := concat($name,'STRF')
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[@OID=$occuroid]/@Name
    (: iterate over all the records that have an --OCCUR data point :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$occuroid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $occurvalue := $record/odm:ItemData[@ItemOID=$occuroid]/@Value
        (: check whether STRF is populated - if so, get the value :)
        let $strfvalue := $record/odm:ItemData[@ItemOID=$strfoid]/@Value
        (: STRF amay NOT be present when OCCUR is present :)
        where $occurvalue and $strfvalue
        return <warning rule="SD1042-A" variable="{data($strfname)}" dataset="{data($name)}" rulelastupdate="2019-09-03" recordnumber="{data($recnum)}">Value of Start Relative to Reference Period ({data($strfname)} should not be populated for non-occurred event or intervation is provided, with value of {data($occurname)}={data($occurvalue)}</warning>
