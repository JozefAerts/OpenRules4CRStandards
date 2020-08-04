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

(: Rule CG0288 - When TSVCDREF = 'CDISC' then TSVALCD = valid code in the  version identified in TSVCDVER :)
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
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Use of the XML4Pharma RESTful web services (SHARE in future) :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/CDISCCTService2/rest/CDISCDefinitionFromNCICode/'
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVALCD, TSVCDREF and TSVCDVER variables :)
    let $tsvalcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVALCD']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
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
	let $datasetname := (
		if($defineversion='2.1') then $itemgroup//def21:leaf/@xlink:href
		else $itemgroup//def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    let $datasetdoc := doc($dataset)
    (: get the records with TSVCDREF='CDISC' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvcdrefoid and @Value='CDISC']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of TSVCDVER :)
        let $tsvcdver := $record/odm:ItemData[@ItemOID=$tsvcdveroid]/@Value
        (: get the value of TSVALCD, which essentially must be an NCI code  :)
        let $tsvalcd := $record/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
        (: generate the webservice request string, like:
        http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CDISCDefinitionFromNCICode/C15228/2016-12-16 :)
        let $webservice := concat($webservicebase,$tsvalcd,'/',$tsvcdver,'.xml')
        (: apply the webservice: when "null" is returned (as string) it is an invalid NCI code for that codelist version,
        if however the NCI code is correct for that version, the CDISC definition is returned, like:  
        "A study in which neither the subject nor the investigator nor the research team interacting with the subject or data during the trial knows what treatment a subject is receiving. (CDISC glossary)"  :)
        let $webserviceresponse := doc($webservice)/XML4PharmaServerWebServiceResponse/Response
        where $webserviceresponse='null'  (: NCI code not found in the given codelist version :)
    return  <error rule="CG0288" dataset="TS" variable="TSVALCD" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">The Value TSVALCD='{data($tsvalcd)}' for version TSVCDVER='{data($tsvalcd)}' for TSVCDREF='CDISC' is not a valid CDISC-CT value this version</error>			
		
	