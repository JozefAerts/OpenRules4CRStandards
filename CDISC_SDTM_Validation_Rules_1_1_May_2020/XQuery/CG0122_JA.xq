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

(: Rule CG0122 - When ARM in ('Screen Failure', 'Not Assigned') then ARM = ACTARM :)
(: Rule CG0122 does NOT apply to SDTMIG v.3.3, only to v.3.2 :)
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
    (: get the OID of the ARM and ACTARM :)
    let $armoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $actarmoid := (
       for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all the records in the DM dataset that have ARM populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARM and ACTARM :)
        let $armvalue := $record/odm:ItemData[@ItemOID=$armoid]/@Value
        let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
        (: When ARM in ('Screen Failure', 'Not Assigned') then ARM = ACTARM :)
        where ($armvalue='Screen Failure' or $armvalue='Not Assigned') and not($armvalue=$actarmvalue)
        return <error rule="CG0122" dataset="DM" variable="ARM" rulelastupdate="2020-06-14" recordnumber="{data($recnum)}">Invalid value for ARM, value='{data($armvalue)}' is expected to be equal to the value of ACTARM='{data($actarmvalue)}'</error>				
		
	