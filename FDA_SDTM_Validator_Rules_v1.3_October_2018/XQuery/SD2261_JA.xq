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
	
(: Rule SD2261: Invalid TSVALCD value for TRT: TSVALCD for TRT record must be a valid unique ingredient identifier from FDA Substance Registration System (SRS) :)
(: This query uses the DailyMed NLM web service - see https://dailymed.nlm.nih.gov/dailymed/webservices-help/v2/uniis_api.cfm
 e.g.: https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?unii_code=1X0094V6JV :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TS dataset :)
let $tsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion = '2.1') then $tsitemgroupdef/def21:leaf/@xlink:href
	else $tsitemgroupdef/def:leaf/@xlink:href
)
let $tsdataset := doc(concat($base,$tsdatasetname))
(: get the OID of the TSPARMCD variable :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of the TSVALCD variable :)
let $tsvalcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVALCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: now get the records TSPARMCD=TRT, but only when there also IS a TSVALCD variable value present :)
for $record in $tsdataset//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='TRT'] and odm:ItemData[@ItemOID=$tsvalcdoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the ItemData point for TSVAL :)
    let $tsval := $record/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    (: now invoke the web service to check whether it is a valid UNII, e.g.:
    https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?unii_code=1X0094V6JV
    :)
    (: ONLY FOR TESTING let $tsval := '1X0094V6JVx' :)
    let $webservice := concat('https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?unii_code=',$tsval)
    let $webserviceresult := doc($webservice) 
    (: this is a document with the structure /uniis/unii/unii_code - it is an invalid code when there is no such an unii element :)
    let $count := count($webserviceresult/uniis/unii/unii_code)
    where $count = 0
    return <error rule="SD2261" dataset="TS" variable="TSVALCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid TSVALCD value for TRT in dataset {data($tsdatasetname)}: TSVALCD for TRT record must be a valid unique ingredient identifier from FDA Substance Registration System (SRS): value '{data($tsval)}' is not a valid unique ingredient identifier from SRS</error>
