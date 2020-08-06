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

(: Rule  : Coded and Decoded values do not have the same Code in CDISC CT - 
Paired variables such as TEST/TESTCD must be populated using terms with the same Codelist Code value in CDISC control terminology. There is one-to-one relationship between paired variable values defined in CDISC control terminology by Codelist Code value :)
(: The rule will only be implemented on TESTCD-TEST pairs :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: iterate over the dataset definitions :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    (: get the name of the dataset :)
    let $name := $datasetdef/@Name
    (: get the OIDs of the --TESTCD and --TEST variables :)
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $testcdname := $definedoc//odm:ItemDef[@OID=$testcdoid]/@Name
    let $testoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TEST')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $testname := $definedoc//odm:ItemDef[@OID=$testoid]/@Name
    (: get the associated codelist :)
    let $testcdcodelistoid := $definedoc//odm:ItemDef[@OID=$testcdoid]/odm:CodeListRef/@CodeListOID
    let $testcodelistoid := $definedoc//odm:ItemDef[@OID=$testoid]/odm:CodeListRef/@CodeListOID
    (: and the codelist itself :)
    let $testcdcodelist := $definedoc//odm:CodeList[@OID=$testcdcodelistoid]  (: this is an XML structure :)
    let $testcodelist := $definedoc//odm:CodeList[@OID=$testcodelistoid]  (: this is an XML structure :)
    (: get the location of the dataset :)
	let $datasetlocation := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the dataset document itself :)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all the records in the dataset, at least when TESTCD and TEST have been defined for the dataset :)
    for $record in $datasetdoc[$testcdoid and $testoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of --TESTCD and of --TEST :)
        let $testcdvalue := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
        let $testvalue := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        (: get the NCI code of the --TESTCD value if there is one.
        the case there is one usually corresponds with an extension to the codelist :)
        (: ATTENTION: case sensitive! :)
        let $testcdncivalue := $testcdcodelist/odm:*[@CodedValue=$testcdvalue]/odm:Alias[@Context='nci:ExtCodeID']/@Name
        let $testncivalue := $testcodelist/odm:*[@CodedValue=$testvalue]/odm:Alias[@Context='nci:ExtCodeID']/@Name
        (: return <test>{data($testcdncivalue)} - {data($testncivalue)}</test> :)
        (: if there is an NCI value for the TESTCD, then the NCI value for the TEST must be identical :)
        where $testcdncivalue and not($testcdncivalue=$testncivalue) 
        return <error rule="CT2003" dataset="{data($name)}" variable="{$testcdname}" recordnumber="{$recnum}" rulelastupdate="2020-06-26">The Coded value  '{data($testcdvalue)}' with NCI code '{data($testcdncivalue)}' and Decode value '{data($testvalue)}' with NCI code '{data($testcdncivalue)}' do not have the same NCI code</error>		

