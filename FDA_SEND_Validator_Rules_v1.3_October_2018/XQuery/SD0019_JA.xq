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

(: Rule SD0019 - Invalid value for --PARM variable:
The value of Parameter (--PARM) variable should be no more than 40 characters in length :)
(: This rule is really outdated! Even CDISC has published test names with > 40 characters. The rule is a relict of the ancient XPT format. :)
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
    (: Get the OID for the TSPARM variable :)
    let $testoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARM']/@OID
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    (: we of course only look into datasets where there really is a --TEST :)
    let $datasetname := $itemgroup//def:leaf/@xlink:href
    let $dataset := concat($base,$datasetname)
    (: iterate over all the records within the TS dataset :)
    for $record in doc($dataset)//odm:ItemGroupData
        (: get the record number :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the TSPARM variable :)
        let $testvalue := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        (: when it has more than 40 characters, give an error :)
        where string-length($testvalue) > 40
        return <error rule="SD0019" dataset="TS" variable="TSPARM" recordnumber="{data($recnum)}" rulelastupdate="2019-08-29">The value for TSPARM in dataset {data($datasetname)} has more than 40 characters: '{data($testvalue)}' was found</error>
