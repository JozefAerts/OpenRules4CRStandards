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

(: Rule CG0450 - When TSPARMCD = 'TRT' then TSVAL is a valid preferred term from FDA Substance Registration System (SRS) :)
(: This query uses the DailyMed NLM web service - see https://dailymed.nlm.nih.gov/dailymed/webservices-help/v2/uniis_api.cfm
 e.g.: http://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?active_moiety=NAFARELIN :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)

(: Get the TS dataset :)
let $tsitemgroupdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsitemgroupdef/def:leaf/@xlink:href
let $tsdataset := doc(concat($base,$tsdatasetname))
(: get the OID of the TSPARMCD variable :)
let $tsparmcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of the TSVAL variable :)
let $tsvaloid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSVAL']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: now get the records TSPARMCD=TRT, but only when there also IS a TSVALCD variable value present :)
for $record in $tsdataset//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='TRT'] and odm:ItemData[@ItemOID=$tsvaloid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the ItemData point for TSVAL :)
    (: REMARK that we are forgiving regarding case-sensitiveness :)
    let $tsval := upper-case($record/odm:ItemData[@ItemOID=$tsvaloid]/@Value)
	let $tsval := replace($tsval,' ','%20')
    (: return <test>{data($tsval)}</test> :)
    (: now invoke the web service to check whether it is a valid UNII, e.g.:
    https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?active_moiety=NAFARELIN
    :)
    (: ONLY FOR TESTING :)
    (: let $tsval := 'NAFARELINx' :)
    let $webservice := concat('https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?active_moiety=',$tsval)
    let $webserviceresult := doc($webservice) 
    (: this is a document with the structure /uniis/unii/unii_code - it is an invalid code when there is no such an unii element :)
    let $count := count($webserviceresult/uniis/unii/unii_code)
    where $count = 0
    return <error rule="CG0450" dataset="TS" variable="TSVAL" rulelastupdate="2020-06-19" recordnumber="{data($recnum)}">Invalid TSVAL value for TRT in dataset {data($tsdatasetname)}: TSVAL='{data($tsval)}' for TRT record must be a valid preferred term from FDA Substance Registration System (SRS): value '{data($tsval)}' is not a valid preferred term identifier from SRS</error>  			
		
	