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
(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the DTHFL and of DTHDTC :)
    let $dthfloid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='DTHFL']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $dhdtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='DTHDTC']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have DTHDTC populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dhdtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of DTHFL :)
        let $dthflvalue := $record/odm:ItemData[@ItemOID=$dthfloid]/@Value
        (: and check whether DTHFL=Y :)
        where not($dthflvalue='Y')
        return <error rule="CG0435" dataset="DM" variable="DTHFL" rulelastupdate="2020-06-19" recordnumber="{data($recnum)}">DTHFL='{data($dthflvalue)}' instead of 'Y', although DTHDTC='{data($dthflvalue)}' is not null</error>	
		
	