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

(: Rule SD2264 - Invalid TSVALCD value for PCLAS:
TSVALCD for PCLAS record must be a valid code from NDF-RT
:)
(: uses NLM webservice - see http://rxnav.nlm.nih.gov/NdfrtAPIREST.html
E.g. http://rxnav.nlm.nih.gov/REST/Ndfrt/parentConcepts.xml?nui=N0000153235 :)
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
	if($defineversion = '2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD and TSVALCD :)
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
(: get the records with TSPARMCD=PCLAS :)
for $pclassrecord in doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='PCLAS']]
    let $recnum := $pclassrecord/@data:ItemGroupDataSeq
    (: and get the value of TSVALCD :)
    let $tsvalcdvalues := $pclassrecord/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    (: just for testing: let $tsvalcdvalue := 'N0000175565' :)
    (: There should be 0 or 1 TSVALCD values, but we don't want to call the web service when there is none :)
    for $tsvalcdvalue in $tsvalcdvalues
	    (: check it using the NLM webservice :)
	    let $webserviceresult := doc(concat('http://rxnav.nlm.nih.gov/REST/Ndfrt/parentConcepts.xml?nui=',$tsvalcdvalue))
	    (: This rerturns an XML document with the structure /ndfrtdata/groupConcepts/concept
	    with child elements conceptName, conceptNui, conceptKind 
	    If the code is invalid, no "concept" element will be present :)
	    where not($webserviceresult/ndfrtdata/groupConcepts/concept)
	    return <error rule="SD2264" dataset="TS" variable="TSVALCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid TSVALCD value={data($tsvalcdvalue)} for PCLAS</error>
