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

(: Rule SD0018 - Invalid value for --TESTCD variable:
The value of a Short Name of Measurement, Test or Examination (--TESTCD) variable should be limited to 8 characters, cannot start with a number, and cannot contain characters other than letters in upper case, numbers, or underscores :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {

   $value = $seq
 } ;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

let $numbers := ("0","1","2","3","4","5","6","7","8","9")

(: iterate over all datasets in the define.xml :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='FINDINGS']
	let $itemgroupdefname := $itemgroup/@Name
    (: get the dataset name and location :)
    let $dsname := $itemgroup/def:leaf/@xlink:href
    let $dataset := concat($base,$dsname)
    (: get the OID of the "--TEST" variable :)
    let $testoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
    where $a = $itemgroup/odm:ItemRef/@ItemOID 
    return $a 
    )
    let $testname := doc(concat($base,$define))//odm:ItemDef[@OID=$testoid]/@Name
    for $record in doc($dataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$testoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $value := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        let $firstchar := substring($value,1,1)
        (: TODO: pattern matching does not seem to work well, though the pattern seems to be correct!  :)
        where string-length($value) > 8 or functx:is-value-in-sequence($firstchar,$numbers) or not(matches($value,'[A-Z_][A-Z0-9_]*'))
        return <error rule="SD0018" recordnumber="{data($recnum)}" dataset="{data($itemgroupdefname)}" variable="{$testname}" rulelastupdate="2019-08-31">Invalid value for Short Name of Measurement, Test or Examination (--TESTCD) variable: it should be limited to 8 characters, cannot start with a number, and cannot contain characters other than letters in upper case, numbers, or underscores. Value '{data($value)}' was found for variable {data($testname)} in dataset {data($datasetname)}.</error>
