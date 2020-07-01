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
	
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
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
(: the location of the MedDRA files (folder) need to be passed :)
declare variable $meddrabase external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $meddrabase := 'file:///e:/Validation_Rules_XQuery/meddra_17_1_english/MedAscii/' :)
let $meddrafile := 'pt.asc' 
let $meddralocation := concat($meddrabase,$meddrafile)
(: read the meddra file line by line :)
let $lines := unparsed-text-lines($meddralocation) 
(: get the preferred term, which is the second field - field separator is the $ character :)
let $ptterms := (
	for $line in $lines
	return upper-case(tokenize($line,'\$')[2])
)  
(: $ptterms know contains all the MedDRA PT terms in UPPERCASE :)
(: iterate over all AE, MH and CE dataset definitions :)
let $definedoc := doc(concat($base,$define))
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='AE' or @Name='MH' or @Name='CE' or @Domain='AE' or @Domain='MH' or @Domain='CE']
    let $name := $itemgroup/@Name
    (: get the OID of the --DECOD variable :)
    let $decodoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DECOD')]/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID
        return $a
    )
    let $decodname := $definedoc//odm:ItemDef[@OID=$decodoid]/@Name
    (: get the dataset location :)
    let $datasetlocation := $itemgroup/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --DECOD :)
        let $decodvalue := $record/odm:ItemData[@ItemOID=$decodoid]/@Value
        (: give an error when the DECOD value is not one of the PT terms of MedDRA - case-insensitive :)
        where $decodvalue and not(functx:is-value-in-sequence(upper-case($decodvalue),$ptterms)) 
        return <error rule="CG0379" dataset="{data($name)}" variable="{data($decodname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-18">Value '{data($decodvalue)}' for {data($decodname)} was not found in the MedDRA dictionary</error>			
		
	