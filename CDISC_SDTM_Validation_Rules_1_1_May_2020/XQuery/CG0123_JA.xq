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

(: Rule CG0123 - ACTARMCD value length <= 20:
The value of Actual Arm Code (ACTARMCD) should be no more than 20 characters in length
:) 
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)

(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARMCD :)
    let $actarmcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have ACTARMCD populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$actarmcdoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARMCD :)
        let $actarmcdvalue := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
        (: and check whether it is not longer than 20 characters :)
        where string-length($actarmcdvalue) > 20
        return <warning rule="CG0123" dataset="DM" variable="ACTARMCD" ulelastupdate="2020-06-14" recordnumber="{data($recnum)}">Invalid value for ACTARMCD in dataset {data($datasetname)}, it's length is more than 20 characters, value='{data($actarmcdvalue)}'</warning>				
		
	