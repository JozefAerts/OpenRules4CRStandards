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

(: Rule SD0083 - Duplicate USUBJID - The value of Subject Identifier for the Study (USUBJID) variable must be unique for each subject within the study - DM :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the OID of USUBJID in define.xml for dataset DM :)
let $usubjidoid :=  (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: and the file where to find the DM records :)
let $datasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dataset := concat($base,$datasetname) 
(: iterate over all records in the DM dataset :)
for $record in doc($dataset)//odm:ItemGroupData
    (: get the value for the SUBJID data point :)
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get all following records with the same value of SUBJID :)
    let $count := count(doc($dataset)//odm:ItemGroupData[@data:ItemGroupDataSeq > $recnum][odm:ItemData[@ItemOID=$usubjidoid][@Value=$usubjidvalue]])
    where $count > 0
    return <error rule="SD0083" dataset="DM" variable="SUBJID" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">Duplicate value of SUBJID={data($usubjidvalue)} - {data($count)} in dataset {data($datasetname)}</error>	
