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

(: Rule SD1004 - ARMCD value length <= 20 
The value of Planned Arm Code (ARMCD) should be no more than 20 characters in length
:)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM and TA datasets:)
let $datasets := $definedoc//odm:ItemGroupDef[@Name='DM' or @Name='TA' or @Name='TV']
(: and iterate over these :)
for $dataset in $datasets
    (: get the dataset name and location :)
    let $name := $dataset/@Name
    let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OID of the ARMCD variable - can be different in each dataset :)
    let $armcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: start iterating over all records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the value of the ARMCD variable :)
    let $armcdvalue := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
    (: and check whether not more than 20 characters  :)
    where string-length($armcdvalue) > 20
    return <error rule="SD1004" dataset="{data($name)}" variable="ARMCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid value for ARMCD={data($armcdvalue)} in dataset {data($datasetname)} - it has more than 20 characters</error>			
		
	