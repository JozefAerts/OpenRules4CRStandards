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

(: Rule SD2263 - Invalid TSVAL value for PCLAS - TSVAL for PCLAS record must be a valid term from NDF-RT :)
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
(: get the OID of the TSVAL variable :)
let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: now get the records TSPARMCD=PCLAS, but only when there also IS a TSVAL variable value present :)
for $record in $tsdataset//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='PCLAS']][odm:ItemData[@ItemOID=$tsvaloid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the ItemData point for TSVAL :)
    let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    (: now invoke the web service to check whether it is a valid NDF-RT, e.g.:
    https://rxnav.nlm.nih.gov/REST/Ndfrt/search?conceptName=Anti-epileptic%20Agent
    :)
    let $webservice := concat('https://rxnav.nlm.nih.gov/REST/Ndfrt/search?conceptName=',$tsval)
    let $webserviceresult := doc($webservice) 
    (: this is a document with the structure /ndfrtdata/groupConcepts/concept/conceptName - it is an invalid code when there is no such an conceptName element :)
    let $count := count($webserviceresult/ndfrtdata/groupConcepts/concept[conceptName=$tsval])
    where $count = 0
    return <error rule="SD2263" dataset="TS" variable="TSVALCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid TSVAL value for PCLASS in dataset {data($tsdatasetname)}: TSVAL for TSPARMCD=PCLAS record must be a valid a valid term from NDF-RT: value '{data($tsval)}' was found</error> 
