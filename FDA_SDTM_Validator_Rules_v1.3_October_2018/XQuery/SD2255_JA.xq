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

(: Rule SD2255 - TSVAL/TSVALCD value mismatch for COMPTRT:
TSVAL and TSVALCD values must be populated from the same name record in FDA Substance Registration System (SRS)
:)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion = '2.1') then $tsdataset/def:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD, TSVAL and TSVALCD variables :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVALCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get all the records that have TSPARMCD=COMPTRT :)
for $record in doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='COMPTRT']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of the TSVAL and TSVALCD variable :)
    let $tsvalcdvalue := $record/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    let $tsvalvalue := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    (: invoke the NLM webservice to check whether this is a valid preferred term :)
    let $webservice := concat('https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?unii_code=',$tsvalcdvalue)
    (: the webservice returns an XML document with the structure /uniis/unii/unii_code and /uniis/unii/active_moiety :)
    let $webserviceresult := doc($webservice)
    let $activemoiety := $webserviceresult/uniis/unii/active_moiety
    (: the value of "active_moiety" must correspond to the value of TSVAL :)
    where not($activemoiety=$tsvalvalue)
    return <error rule="SD2255" dataset="TS" variable="TSVALCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">TSVAL/TSVALCD value mismatch for COMPTRT, TSVALCD={data($tsvalcdvalue)}, TSVAL={data($tsvalvalue)} - NLM webservice provides active moeity={data($activemoiety)}</error>
