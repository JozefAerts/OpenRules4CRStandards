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

(: TODO: requires further testing :)
(: Rule SD0031 - Missing values for --STDTC, --STRF and --STRTPT, when --ENDTC, --ENRF or --ENRTPT is provided
Start Date/Time of Observation (--STDTC), Start Relative to Reference Period (--STRF) or Start Relative to Reference Time Point (--STRTPT) should not be NULL, 
when End Date/Time of Observation (--ENDTC), End Relative to Reference Period (--ENRF) or End Relative to Reference Time Period (--ENRTPT) is not NULL
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :) 
 
(: iterate over all the datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or @Domain='SE' or @Domain='SV']
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: Get the OID and Name of the STDTC, STRF, STRTPT variables :)
    let $stdtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdtcname := doc(concat($base,$define))//odm:ItemDef[@OID=$stdtcoid]/@Name
    let $strfoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRF')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strfname := doc(concat($base,$define))//odm:ItemDef[@OID=$strfoid]/@Name
    let $strtptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strtptname := doc(concat($base,$define))//odm:ItemDef[@OID=$strtptoid]/@Name
    (: and of the ENDTC, ENRF and ENRTPT variables :) 
    let $endtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $endtcname := doc(concat($base,$define))//odm:ItemDef[@OID=$endtcoid]/@Name
    let $enrfoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrfname := doc(concat($base,$define))//odm:ItemDef[@OID=$enrfoid]/@Name
    let $enrtptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := doc(concat($base,$define))//odm:ItemDef[@OID=$enrtptoid]/@Name
    (: iterate over all records that do have a --ENDTC, --ENRF or --ENRTPT data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$endtcoid] or odm:ItemData[@ItemOID=$enrfoid] or odm:ItemData[@ItemOID=$enrtptoid]] 
    let $recnum := $record/@data:ItemGroupDataSeq
    (: check whether a value for STDTC, STRF, or STRTPT is present :)
    where not($record/odm:ItemData[@ItemOID=$stdtcoid]) and not($record/odm:ItemData[@ItemOID=$strfoid]) and not($record/odm:ItemData[@ItemOID=$strtptoid]) 
    return <warning rule="SD0031" rulelastupdate="2019-08-19" recordnumber="{data($recnum)}">Missing values for {data(concat($name,'STDTC'))}, {data(concat($name,'STRF'))} and {data(concat($name,'STRTPT'))}, when one of {data(concat($name,'ENDTC'))}, {data(concat($name,'ENRF'))} or {data(concat($name,'ENRTPT'))} is provided in dataset {data($name)} </warning>	
