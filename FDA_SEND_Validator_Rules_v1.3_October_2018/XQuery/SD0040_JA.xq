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
	
(: Rule SD0040 - 'Inconsistent value for --TEST within --TESTCD
All values of Name of Measurement, Test or Examination (--TEST) should be the same for a given value of Short Name of Measurement, Test or Examination (--TESTCD)
:)
(: Using a "GROUP BY", the speed is enormously improved  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all FINDINGS datasets that have --TESTCD and --TEST :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@def:Class='FINDINGS']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OID of --TESTCD and --TEST :)
    let $testcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $testcdname := doc(concat($base,$define))//odm:ItemDef[@OID=$testcdoid]/@Name
    let $testoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TEST')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $testname := doc(concat($base,$define))//odm:ItemDef[@OID=$testoid]/@Name
    (: Group the records by the value of --TESTCD :)
    let $orderedrecords := (
        for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$testcdoid]]
            group by 
            $b:=$record/odm:ItemData[@ItemOID=$testcdoid]/@Value
            return element group {  
                $record
            }
        )
    (: all the records in the same group have the same value for --TESTCD. 
    They must also all have the same value for --TEST :)
    for $group in $orderedrecords
        let $testcdvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$testcdoid]/@Value
        for $record in $group/odm:ItemGroupData[position()>1]  (: start from the second one  :)
            let $recnum := $record/@data:ItemGroupDataSeq
            (: get the value of --TEST :)
            let $testvalue := $record/odm:ItemData[@ItemOID=$testoid]/@Value
            (: take the previous record in the same group, and take its --TEST value :)
            let $precrecord := $record/preceding-sibling::odm:ItemGroupData[1]  (: as they come in descending order :)
            let $recnum2 := $precrecord/@data:ItemGroupDataSeq
            let $testvalue2 := $precrecord/odm:ItemData[@ItemOID=$testoid]/@Value 
            (: when the value of--TEST in both records is different, report an error :)
            where not($testvalue2 = $testvalue) 
                return <error rule="SD0040" dataset="{data($name)}" variable="{data($testcdname)}" rulelastupdate="2019-10-15" recordnumber="{data($recnum)}">Inconsistent value for {data($testname)} within {data($testcdname)}='{data($testcdvalue)}' in dataset {data($datasetname)}. Following values were found: record number {data($recnum2)}: {data($testname)}={data($testvalue2)} - record number {data($recnum)}: {data($testname)}={data($testvalue)}</error>	
