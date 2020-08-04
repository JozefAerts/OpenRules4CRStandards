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
	
(: Rule CG0372 - --TESTCD <= 8 chars and contains only letters, numbers, and underscores and can not start with a number :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
 } ;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
let $numbers := ("0","1","2","3","4","5","6","7","8","9")
(: iterate over all datasets in the define.xml :)
for $itemgroup in $definedoc//odm:ItemGroupDef
	let $itemgroupdefname := $itemgroup/@Name
    (: get the dataset name and location :)
	let $datasetname := (
		if($defineversion='2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: get the OID of the "--TEST" variable :)
    let $testoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID 
        return $a 
    )
    let $testname := $definedoc//odm:ItemDef[@OID=$testoid]/@Name
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$testoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $value := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        let $firstchar := substring($value,1,1)
        (: TODO: pattern matching does not seem to work well, though the pattern seems to be correct!  :)
        where string-length($value) > 8 or functx:is-value-in-sequence($firstchar,$numbers) or not(matches($value,'[A-Z_][A-Z0-9_]*'))
        return <error rule="CG0372" recordnumber="{data($recnum)}" dataset="{data($itemgroupdefname)}" variable="{$testname}" rulelastupdate="2020-08-04">{data($testname)}='{data($value)}' must be not more than 8 chars long and contains only letters, numbers, and underscores and can not start with a number</error>			
		
	