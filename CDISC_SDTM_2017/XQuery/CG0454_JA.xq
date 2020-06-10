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

(: Rule CG0454 - When TSPARMCD = 'PCLAS' then TSVALCD is a valid code from NDF-RT :)
(: uses NLM webservice - see http://rxnav.nlm.nih.gov/NdfrtAPIREST.html
E.g. http://rxnav.nlm.nih.gov/REST/Ndfrt/parentConcepts.xml?nui=N0000153235 :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: get the TS dataset :)
let $tsdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD and TSVALCD :)
let $tsparmcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSVALCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the records with TSPARMCD=PCLAS :)
for $pclassrecord in doc($tsdatasetlocation)//odm:ItemGroupData[1]
    let $recnum := $pclassrecord/@data:ItemGroupDataSeq
    (: and get the value of TSVALCD :)
    let $tsvalcdvalues := $pclassrecord/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    (: just for testing: let $tsvalcdvalue := ('N0000175565x') :)
    (: There should be 0 or 1 TSVALCD values, but we don't want to call the web service when there is none :)
    for $tsvalcdvalue in $tsvalcdvalues
	    (: check it using the NLM webservice :)
	    let $webserviceresult := doc(concat('https://rxnav.nlm.nih.gov/REST/Ndfrt/parentConcepts.xml?nui=',$tsvalcdvalue))
	    (: This returns an XML document with the structure /ndfrtdata/groupConcepts/concept
	    with child elements conceptName, conceptNui, conceptKind 
	    If the code is invalid, no "concept" element will be present :)
	    where not($webserviceresult/ndfrtdata/groupConcepts/concept)
	    return <error rule="CG0454" dataset="TS" variable="TSVALCD" rulelastupdate="2015-02-11" recordnumber="{data($recnum)}">Invalid TSVALCD value={data($tsvalcdvalue)} for TSPARMCD=PCLAS</error>			
		
		