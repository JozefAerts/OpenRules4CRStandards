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

(: Rule CG0118 - When ACTARM not in ('Screen Failure', 'Not Assigned', 'Not Treated', 'Unplanned Treatment') then ACTARM in TA.ARM :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: get the TA dataset and the ARM (Arm Name( OID in TA :)
let $tadataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']
let $tadatasetname := $tadataset/def:leaf/@xlink:href
let $tadatasetlocation := concat($base,$tadatasetname)
let $armfromtaoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ARM']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
    return $a
)
(: make an array/sequence with all TA-ARM values, take it from the dataset itself, not from the define.xml codelist :)
let $armsequence := distinct-values(
    for $itemdata in doc($tadatasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$armfromtaoid]
    return $itemdata/@Value
)
(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARM :)
    let $actarmoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have ACTARM populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$actarmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARM :)
        let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
        (: When ACTARM is not in ('Screen Failure', 'Not Assigned', 'Not Treated', 'Unplanned Treatment') then ACTARM must be in TA.ARM :)
        where not($actarmvalue='Screen Failure') and not($actarmvalue='Not Assigned') and not($actarmvalue='Not Treated') and not($actarmvalue='Unplanned Treatment') and not(functx:is-value-in-sequence($actarmvalue,$armsequence)) 
        return <error rule="CG0118" dataset="DM" variable="ACTARM" rulelastupdate="2017-02-18" recordnumber="{data($recnum)}">Invalid value for ACTARM, value={data($actarmvalue)} is not one of ('Screen Failure', 'Not Assigned', 'Not Treated', 'Unplanned Treatment') and is not found in TA</error>						
		
		