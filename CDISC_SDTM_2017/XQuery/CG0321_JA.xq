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

(: Rule CG0321 - When custom domain present in study then custom domain is based on one of the observation classes :)
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
    let $domain := $itemgroupdef/@Domain
    (: get the Class :)
    let $class := upper-case($itemgroupdef/@def:Class)
    (: Class must be one of INTERVENTIONS, FINDINGS, EVENTS :)
    where $class='INTERVENTIONS' or $class='FINDINGS' or $class='EVENTS'
    return <error rule="CG0321" dataset="{data($name)}" rulelastupdate="2017-03-07">The custom dataset/domain {data($name)} is not based on one of the observation classes 'INTERVENTIONS', 'FINDINGS', 'EVENTS'. Class '{data($class)}' was found</error>						
		
		