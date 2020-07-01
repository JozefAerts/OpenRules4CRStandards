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
	
(: Rule SD0049 - Missing value for --STTPT, when --STRTPT is populated:
Start Reference Time Point (--STTPT) must not be NULL, when Start Relative to Reference Time Point (--STRTPT) is provided
:)
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

(: iterate over all the datasets within INTERVENTIONS, EVENTS, FINDINGS, SE, SV:)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Domain='SE' or @Domain='SV']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OIDs of the STTPT and STRTPT variables (if any) :)
    let $sttptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $sttptname := doc(concat($base,$define))//odm:ItemDef[@OID=$sttptoid]/@Name
    let $strtptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strtptname := doc(concat($base,$define))//odm:ItemDef[@OID=$strtptoid]/@Name
    (: iterate over all the records in the dataset for which there is a STRTPT data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData/@ItemOID=$strtptoid]
    let $recnum := $record/@data:ItemGroupDataSeq
        (: and check whether there is STTPT data point :)
        let $sttptvalue := $record/odm:ItemData[@ItemOID=$sttptoid]/@Value
        let $strtptvalue := $record/odm:ItemData[@ItemOID=$strtptoid]/@Value
        where not($sttptvalue)
        return <warning rule="SD0049" rulelastupdate="2019-08-19" recordnumber="{data($recnum)}">Missing value for {data($sttptname)}, when {data($strtptname)} is populated, value = {data($strtptvalue)}</warning>
