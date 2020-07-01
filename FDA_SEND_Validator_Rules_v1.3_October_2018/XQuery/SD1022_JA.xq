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

(: Rule SD1022 - Invalid value for QNAM variable:
The value of Qualifier Variable Name (QNAM) should be limited to 8 characters, cannot start with a number, and cannot contain characters other than letters in upper case, numbers, or underscores
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
(: Get all the SUPPxx datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the QNAM variable :)
    let $qnamoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='QNAM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: Get the QNAM value :)
    let $qnamvalue := $record/odm:ItemData[@ItemOID=$qnamoid]/@Value
    (: and check whether more than 8 characters and that the character types are correct :)
    where string-length($qnamvalue) > 8 or not(matches($qnamvalue,'[A-Z_][A-Z0-9_]*'))
    return <warning rule="SD1022" variable="QNAM" dataset="{data($name)}" rulelastupdate="2019-09-03" recordnumber="{data($recnum)}">Invalid value for QNAM in dataset {data($datasetname)} - Label={data($qnamvalue)} has more than 8 characters or starts with a number or contains characters other than letters in upper case, numbers, or underscores</warning>
