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
		
(: Rule SD1043 - Inconsistent value for --TESTCD within --TEST
All values of Short Name of Measurement, Test or Examination (--TESTCD) should be the same for a given value of Name of Measurement, Test or Examination (--TEST)
:)
(: Using a "GROUP BY", the speed is enormously improved  :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets that have --TESTCD and --TEST :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname or @Domain=$datasetname]
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$dsname)
    (: and get the OID of --TESTCD and --TEST :)
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $testcdname := $definedoc//odm:ItemDef[@OID=$testcdoid]/@Name
    let $testoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TEST')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $testname := $definedoc//odm:ItemDef[@OID=$testoid]/@Name
    (: Group the records by the value of --TEST :)
    let $orderedrecords := (
        for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$testoid]]
            group by 
            $b:=$record/odm:ItemData[@ItemOID=$testoid]/@Value
            return element group {  
                $record
            }
        )
    (: all the records in the same group have the same value for --TEST. 
    They must also all have the same value for --TESTCD :)
    for $group in $orderedrecords
        let $testvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$testoid]/@Value
        for $record in $group/odm:ItemGroupData[position()>1]  (: start from the second one  :)
            let $recnum := $record/@data:ItemGroupDataSeq
            let $testcdvalue := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
            (: take the previous record in the same group, and take its --TESTCD value :)
            let $precrecord := $record/preceding-sibling::odm:ItemGroupData[1]  (: as they come in descending order :)
            let $recnum2 := $precrecord/@data:ItemGroupDataSeq
            let $testcdvalue2 := $precrecord/odm:ItemData[@ItemOID=$testcdoid]/@Value 
            let $recnum2 := $precrecord/@data:ItemGroupDataSeq
            (: when the value of--TESTCD in both records is different, report an error :)
            where not($testcdvalue2 = $testcdvalue) 
                return <error rule="SD1043" dataset="{data($name)}" variable="{data($testname)}" rulelastupdate="2019-08-14" recordnumber="{data($recnum)}">Inconsistent value for {data($testcdname)} within {data($testname)}='{data($testvalue)}' in dataset {data($datasetname)}. Following values were found: record number {data($recnum2)}: {data($testcdname)}={data($testcdvalue2)} - record number {data($recnum)}: {data($testcdname)}={data($testcdvalue)}</error>	
