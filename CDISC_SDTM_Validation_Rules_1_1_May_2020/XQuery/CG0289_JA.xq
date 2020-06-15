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

(: Rule CG0289 - When TSVCDREF = 'CDISC' then TSVCDVER = valid published version (date) :)
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
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Method 2: Uses XML4Pharma RESTful web services (SHARE in future) :)
let $webservice := 'http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CodeListVersions'
let $cdiscctversions := doc($webservice)/XML4PharmaServerWebServiceResponse/Response/CodeListVersion
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVCDVER and TSVCDREF variables :)
    let $tsvcdrefoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVCDREF']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsvcdveroid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVCDVER']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset :)
    let $datasetname := $itemgroup//def:leaf/@xlink:href
    let $dataset := concat($base,$datasetname)
    let $datasetdoc := doc($dataset)
    (: get the TSVCDVER values in the records with TSVCDREF='CDISC' :)
    for $tsvcdver in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvcdrefoid and @Value='CDISC']]/odm:ItemData[@ItemOID=$tsvcdveroid]/@Value
	    (: the value must be one from the list (if present at all) :)
	    where $tsvcdver and not(functx:is-value-in-sequence($tsvcdver,$cdiscctversions))
	    return  <error rule="CG0289" dataset="TS" variable="TSVCDVER" rulelastupdate="2017-02-28">The Value TSVCDVER='{data($tsvcdver)}' for TSVCDREF='CDISC' is not recognized as a valid CDISC-CT version from the list ({data($cdiscctversions)})</error>
	    		
	