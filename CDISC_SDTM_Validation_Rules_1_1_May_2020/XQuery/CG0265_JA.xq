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

(: Rule CG0265 - When TSVAL != null and TSVALCD != null then TSVALCD and TSVAL have a one-to-one relationship :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all TS datasets - there should only be one :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TS']
    let $name := $datasetdef/@Name
	let $datasetname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetlocation:= concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OIDs of TSVAL and TSVALCD :)
    let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsvalcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVALCD']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: Get all unique values of TSVALCD :)
    let $tsvalcduniquevalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value)
    (: iterate over the unique TSVALCD values and get the records :)
    for $tsvalcduniquevalue in $tsvalcduniquevalues
        (: get all the records :)
        let $uniquetsvalcdrecords := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvalcdoid][@Value=$tsvalcduniquevalue]]
        (: get the unique values for TSVAL within each of the unique TSVALCD values, and count them :)
        let $uniquetsvalvalues := distinct-values($uniquetsvalcdrecords/odm:ItemData[@ItemOID=$tsvaloid]/@Value)
        let $uniquetsvalvaluescount := count($uniquetsvalvalues)
        (: the value of the count of unique TSVAL values for each TSVALCD must be 1 :)
        where not($uniquetsvalvaluescount = 1) 
        return <error rule="CG0265" dataset="{data($name)}" variable="TSVALCD" rulelastupdate="2020-08-04">Inconsistent value for TSVAL within TSVALCD in dataset {data($datasetname)}. {data($uniquetsvalvaluescount)} different TSVAL values were found for TSVALCD={data($tsvalcduniquevalue)}</error>	
		
	