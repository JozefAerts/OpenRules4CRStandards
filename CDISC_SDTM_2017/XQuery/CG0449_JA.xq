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

(: Rule CG0449 - When TSPARMCD in ('INDIC', 'TDIGRP') then TSVALCD is a valid concept identifier from SNOMED CT :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetlocation := concat($base,$tsdatasetname)
let $datasetdoc := doc($tsdatasetlocation)
(: get the OID of the TSPARMCD and TSVALCD variables :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVALCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get all the records that have TSPARMCD=INDIC or TSPARMCD=TDIGRP :)
for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and (@Value='INDIC' or @Value='TDIGRP')]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSPARMCD  :)
    let $tsparmcdvalue := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
    (: get the value of the TSVAL variable :)
    let $tsvalcdvalues := $record/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    (: TESTING ONLY let $tsvalcdvalues := ('12345678') :)
    (: There should be zero or one such value, but we don't want to call the web service when there is none :)
    for $tsvalcdvalue in $tsvalcdvalues
	    (: invoke the NLM webservice to check whether this is a valid preferred term :)
	    let $webservice := concat('https://rxnav.nlm.nih.gov/REST/SnomedCT/status?id=',$tsvalcdvalue)
	    (: the webservice returns an XML document with the structure /snomedctStatus/status - the value should be '1' - '-1' means an invalid satus :)
	    let $webserviceresult := doc($webservice)
	    let $status := $webserviceresult/snomedctStatus/status
	    where $status != 1
	    return <error rule="CG0449" dataset="TS" variable="TSVALCD" rulelastupdate="2017-03-24" recordnumber="{data($recnum)}">Invalid TSVALCD, value={data($tsvalcdvalue)} for TSPARMCD=INDIC is not a valid SNOMED-CT code in dataset TS</error>
		
		