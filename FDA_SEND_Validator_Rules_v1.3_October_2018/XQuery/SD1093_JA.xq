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

(: Rule SD1093 - --ENDY variable value is imputed:
Study Day of End (--ENDY) variable value should be not be imputed. It may be only populated, when both End Study Date/Time (--ENDTC) and Subject Reference Start Date/Time (RFSTDTC) variables values are provided, and both of them include complete date part.
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: get the location of the DM dataset :)
let $dmdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
let $dmdatasetlocation := concat($base,$dmdatasetname)
(: and the OIDs of the USUBJID and RFSTDTC variables :)
let $dmusubjidoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
)
let $rfstdtcoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RFSTDTC']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
)
(: iterate over all datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Domain='SE' or @Domain='SV']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the SDTY and STDTC variable :)
    let $endyoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENDY')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a  
    )
    let $endyname := doc(concat($base,$define))//odm:ItemDef[@OID=$endyoid]/@Name
    let $endtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a  
    )
    let $endtcname := doc(concat($base,$define))//odm:ItemDef[@OID=$endtcoid]/@Name
    (: and the OID of USUBJID in this dataset (can be different from in DM) :)
    let $usubjidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset that DO have both a ENDCT value  :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$endtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $endtcvalue := $record/odm:ItemData[@ItemOID=$endtcoid]/@Value
        (: check whether it is a complete date :)
        let $iscompletestdtcdate := string-length($endtcvalue) >= 10  (: boolean :)
        (: get the USUBJID and get the corresponding RFSTDTC in the DM dataset :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: taking worst case scenario into account that there is more than 1 record for a USUBJID in DM - take the first one :)
        let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: and check whether RFSTDTC is a complete date :)
        let $iscompleterfstdtcdate := string-length($rfstdtcvalue) >= 10
        (: Get the value of the STDY variable (if any) :)
        let $endyvalue := $record/odm:ItemData[@ItemOID=$endyoid]/@Value
        (: ENDY may NOT be populated when of RFSTDTC or ENDTC is an incomplete date :)
        where $endyoid and (not($iscompletestdtcdate) or not($iscompleterfstdtcdate)) and $endyvalue
        return <error rule="SD1093" dataset="{data($name)}" variable="{data($endyname)}" rulelastupdate="2015-02-11" recordnumber="{data($recnum)}">{data($endyname)} variable value {data($endyvalue)} is imputed although one of {data($endtcname)} (value={data($endtcvalue)}) or RFSTDTC (value={data($rfstdtcvalue)}) is not a complete date</error>
