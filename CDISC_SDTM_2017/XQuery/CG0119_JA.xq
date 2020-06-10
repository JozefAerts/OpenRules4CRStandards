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

(: Rule CG0119 - When ACTARM in ('Screen Failure', 'Not Assigned') then ACTARM = ARM :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARM and of ARM :)
    let $actarmoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $armoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have ACTARM populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$actarmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARM and of ARM :)
        let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
        let $armvalue := $record/odm:ItemData[@ItemOID=$armoid]/@Value
        (: When ACTARM is in ('Screen Failure', 'Not Assigned') then ARM must be equal to ARMCD :)
        where ($actarmvalue='Screen Failure'  or  $actarmvalue='Not Assigned') and not($actarmvalue=$armvalue)
        return <error rule="CG0119" dataset="DM" variable="ACTARM" rulelastupdate="2017-02-18" recordnumber="{data($recnum)}">Invalid value for ARM, value='{data($armvalue)}', expected value='{data($actarmvalue)}' </error>				
		
		