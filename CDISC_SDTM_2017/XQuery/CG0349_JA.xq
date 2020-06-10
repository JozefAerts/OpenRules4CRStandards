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

(: Rule CG0349 - When Custom domain and variable name is not STUDYID, DOMAIN, USUBJID, POOLID, SPDEVID, VISIT, VISITNUM, VISITDY, ELEMENT, TAETORD, EPOCH, then Variable name begins with the 2-character domain code :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
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
(: list of the variables that do not need to start with the domain name :)
let $vars := ('STUDYID', 'DOMAIN', 'USUBJID', 'POOLID', 'SPDEVID', 'VISIT', 'VISITNUM', 'VISITDY', 'ELEMENT', 'TAETORD', 'EPOCH')
(: get the define.xml document :)
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get a list of all Findings domains defined by SDTM for IG version 3.2 :)
let $findingsdomains := doc('http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/Findings/3.2')/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: get a list of all Interventions domains defined by SDTM for IG version 3.2 :)
let $interventionsdomains := doc('http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/Interventions/3.2')/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: get a list of all the Events domains defined by SDTM for IG version 3.2 :)
let $eventsdomains := doc('http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/Events/3.2')/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: combine the 3 lists into a single one :)
let $observationsclassdomains := ($findingsdomains,$eventsdomains,$interventionsdomains)
(: we also need the list of special purpose and trial design domains :)
let $specialdomains := ('DM','CO','SV','SE','TE','TA','TV','TX','TI','TS')
(: iterate over all dataset definitions, except for SUPPxx datasets and RELREC dataset that are custom domains (i.e. not in the list).
Remark that this supposes that custom domain names consist of 2 characters (no splits) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[not(starts-with(@Name,'SUPP'))][not(@Name='RELREC')][not(functx:is-value-in-sequence(@Name,$observationsclassdomains))][not(functx:is-value-in-sequence(@Name,$specialdomains))]
    (: get name and domain :)
    let $name := $itemgroupdef/@Name
    let $domain := (     (: get the domain either from the Domain attribute or from the 2 first characters of the datasetname :)
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2)
    )
    (: iterate over all variables in the dataset and get their name :)
    for $itemref in $itemgroupdef/odm:ItemRef
        let $itemoid := $itemref/@ItemOID
        let $varname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
        (: the variable name must be one of the list OR start with the domain name :)
        where not(functx:is-value-in-sequence($varname,$vars)) and not(starts-with($varname,$domain))
        return <error rule="CG0349" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2017-03-14">Variable {data($varname)} must start with the first 2 characters of the domain code '{data($domain)}' in the custom dataset {data($name)}</error>			
		
		