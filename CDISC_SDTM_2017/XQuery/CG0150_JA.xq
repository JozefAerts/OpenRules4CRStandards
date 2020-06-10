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

(: Rule CG0150 - SUBJID unique within a study :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the OID of SUBJID in define.xml for dataset DM :)
let $subjidoid :=  doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef[4]/@ItemOID (: It must always be the fourth one :)
(: and the file where to find the DM records :)
let $datasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
let $dataset := concat($base,$datasetname) 
(: iterate over all records in the DM dataset :)
for $record in doc($dataset)//odm:ItemGroupData
    (: get the value for the SUBJID data point :)
    let $subjidvalue := $record/odm:ItemData[@ItemOID=$subjidoid]/@Value
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get all following records with the same value of SUBJID :)
    let $count := count(doc($dataset)//odm:ItemGroupData[@data:ItemGroupDataSeq > $recnum][odm:ItemData[@ItemOID=$subjidoid][@Value=$subjidvalue]])
    where $count > 0
    return <error rule="CG0150" dataset="DM" variable="SUBJID" rulelastupdate="2017-02-19" recordnumber="{data($recnum)}">Duplicate value of SUBJID={data($subjidvalue)} - {data($count)} in dataset {data($datasetname)}</error>			
		
		