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
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
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
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: Get the SDTM-IG version from the define.xml (default 3.2) :)
let $sdtmigversion := (
	if($defineversion='2.0' and $definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']/@def:StandardVersion ) 
		then $definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']/@def:StandardVersion 
	else if ($defineversion='2.1' and $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG' and @Name='SDTMIG']) 
		then $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG' and @Name='SDTMIG']/@Version
	else '3.2'
)
let $webservice := 'http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/' 
(: get a list of all Findings domains defined by SDTM for the given SDTM-IG version :)
let $findingsdomains := doc(concat($webservice,'Findings/',$sdtmigversion,'.xml'))/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: get a list of all Interventions domains defined by SDTM for the given SDTM-IG version :)
let $interventionsdomains := doc(concat($webservice,'Interventions/',$sdtmigversion,'.xml'))/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: get a list of all the Events domains defined by SDTM for the given SDTM-IG version :)
let $eventsdomains := doc(concat($webservice,'Events/',$sdtmigversion,'.xml'))/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
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
    let $class := (
		if($defineversion='2.1') then upper-case($itemgroupdef/def21:Class/@Name)
		else upper-case($itemgroupdef/@def:Class)
	)
    (: Class must be one of INTERVENTIONS, FINDINGS, EVENTS, FINDINGS ABOUT :)
    where not($class='INTERVENTIONS' or $class='FINDINGS' or $class='EVENTS' or $class='FINDINGS ABOUT')
    return <error rule="CG0321" sdtmigversion="{data($sdtmigversion)}" dataset="{data($name)}" rulelastupdate="2020-08-04">The custom dataset/domain {data($name)} is not based on one of the observation classes 'INTERVENTIONS', 'FINDINGS', 'EVENTS'. Class '{data($class)}' was found</error>						
		
	