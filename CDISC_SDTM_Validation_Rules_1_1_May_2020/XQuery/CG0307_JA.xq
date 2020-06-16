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

(: Rule CG0307 - TSPARM and TSPARMCD have a one-to-one relationship :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all TS datasets - there should only be one :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TS']
    let $name := $datasetdef/@Name
    let $datasetname := $datasetdef/def:leaf/@xlink:href
    let $datasetlocation:= concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OIDs of TSPARM and TSPARMCD :)
    let $tsparmoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARM']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: Get all unique values of TSPARMCD :)
    let $tsparmcduniquevalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value)
    (: iterate over the unique TSPARMCD values and get the records :)
    for $tsparmcduniquevalue in $tsparmcduniquevalues
        (: get all the records :)
        let $uniquetsparmcdrecords := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid][@Value=$tsparmcduniquevalue]]
        (: get the unique values for TSPARM within each of the unique TSPARMCD values, and count them :)
        let $uniquetsparmvalues := distinct-values($uniquetsparmcdrecords/odm:ItemData[@ItemOID=$tsparmoid]/@Value)
        let $uniquetsparmvaluescount := count($uniquetsparmvalues)
        (: the value of the count of unique TSPARM values for each TSPARMCD must be 1 :)
        where not($uniquetsparmvaluescount = 1) 
        return <error rule="CG0307" dataset="{data($name)}" variable="TSPARMCD" rulelastupdate="2010-06-15">Inconsistent value for TSPARM within TSPARMCD in dataset {data($datasetname)}. {data($uniquetsparmvaluescount)} different TSPARM values were found for TSPARMCD={data($tsparmcduniquevalue)}</error>				
		
	