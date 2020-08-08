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
	
(: Attention: this is about the preferred term CODE, not the name - e.g. 10000002  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
declare variable $meddrabase external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $meddrabase := 'file:///e:/Validation_Rules_XQuery/meddra_17_1_english/MedAscii/' :)
let $meddrafile := 'pt.asc' 
let $meddralocation := concat($meddrabase,$meddrafile)
(: read the meddra file line by line :)
let $lines := unparsed-text-lines($meddralocation) 
(: get the preferred term codes, which is the first fied - field separator is the $ character :)
let $ptcodes := (
	for $line in $lines
	return tokenize($line,'\$')[1]
)  
(: $ptcodes know contains all the MedDRA PT codes :)
(: iterate over all AE, MH and CE dataset definitions :)
let $definedoc := doc(concat($base,$define))
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='AE' or @Name='MH' or @Name='CE' or @Domain='AE' or @Domain='MH' or @Domain='CE']
    let $name := $itemgroup/@Name
    (: get the OID of the --PTCD variable :)
    let $ptcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PTCD')]/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID
        return $a
    )
    let $ptcdname := $definedoc//odm:ItemDef[@OID=$ptcdoid]/@Name
    (: get the dataset location :)
	let $datasetlocation := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --PTCD :)
        let $ptcdvalue := $record/odm:ItemData[@ItemOID=$ptcdoid]/@Value
        (: give an error when the PTCD value is not one of the PT codes of MedDRA :)
        where $ptcdvalue and not(functx:is-value-in-sequence($ptcdvalue,$ptcodes)) 
        return <error rule="SD2007" dataset="{data($name)}" variable="{data($ptcdname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08">Value '{data($ptcdvalue)}' for {data($ptcdname)} was not found in the MedDRA dictionary</error>
