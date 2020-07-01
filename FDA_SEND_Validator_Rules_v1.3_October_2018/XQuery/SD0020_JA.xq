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

(: Rule SD0020 - Invalid value for --PARMCD variable:
The value of Parameter Short Name (--PARMCD) variables should be no more than 8 characters in length :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSPARMCD variable :)
    let $testcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $datasetname := $itemgroup//def:leaf/@xlink:href
    let $dataset := concat($base,$datasetname)
    (: iterate over all the records within the TS dataset :)
    for $record in doc($dataset)//odm:ItemGroupData
        (: get the record number :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the TSPARM variable :)
        let $testvalue := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
        (: when it has more than 8 characters, give an error :)
        where string-length($testvalue) > 8
        return <error rule="SD0020" dataset="TS" variable="TSPARMCD" recordnumber="{data($recnum)}" rulelastupdate="2019-08-29">The value for TSPARMCD in dataset {data($datasetname)} has more than 8 characters: '{data($testvalue)}' was found</error>