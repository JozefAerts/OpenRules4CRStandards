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

(: Rule SD0017 - Invalid value for --TEST variable:
The value of Name of Measurement, Test or Examination (--TEST) should be no more than 40 characters in length :)
(: This rule is really outdated! Even CDISC has published test names with > 40 characters. The rule is a relict of the ancient XPT format. 
ALSO:IETEST is an exception: may be up to 200 characters :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets and variables in the define.xml :)
for $itemgroup in $definedoc//odm:ItemGroupDef
	let $itemgroupdefname := $itemgroup/@Name
    (: Get the @Domain value when present, otherwise the @Name value  - 
    this is for allowing 'splitted' domains, e.g. @Name=QSCG @Domain=QS :)
    let $datasetname := $itemgroup/@Name
    let $domain := (
        if($itemgroup/@Domain != '') then $itemgroup/@Domain
        else $itemgroup/@Name
    )
    (: The --TEST variable is the concatenation of the domain code and 'TEST' :)
    let $testvar := concat($domain,'TEST')
    (: Get the OID for the --TEST variable :)
    let $testoid := (
        for $a in $definedoc//odm:ItemDef[@Name=$testvar]/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name=$datasetname]/odm:ItemRef/@ItemOID
        return $a
    )
    (: we of course only look into datasets where there really is a --TEST :)
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    (: iterate over all the records where there is a --TEST variable :)
    for $record in doc($dataset)//odm:ItemGroupData
        (: get the record number :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the --TEST variable :)
        let $testvalue := $record/odm:ItemData[@ItemOID=$testoid]/@Value
        (: when it has more than 40 characters, give an error.
        Attention: IETEST is an exception (may be up to 200 characters) :)
        where string-length($testvalue) > 40 and not($testvar='IETEST')
        return <error rule="SD0017" recordnumber="{data($recnum)}" variable="{data($testvar)}" dataset="{data($itemgroupdefname)}" rulelastupdate="2020-08-08">The value for {data($testvar)} has more than 40 characters: '{data($testvalue)}' was found</error>
