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

(: Rule CG0351 - Variables not in Model List of Allowed Variables for Observation Class are in SUPPQUAL :)
(: This rule implementation uses a RESTful web service :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
let $base := 'LZZT_SDTM_Dataset-XML/' 
let $define := 'define_2_0.xml' 
let $definedoc := doc(concat($base,$define)) 
(: Get the SDTM-IG version from the define.xml (default "3.2" :)
let $sdtmigversion := (
	if ($definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']/@def:StandardVersion)
		then $definedoc//odm:MetaDataVersion/@def:StandardVersion
    else '3.2'
)
(: The base of the RESTful web service that we are going to use :)
let $webservicebase := concat('http://www.xml4pharmaserver.com:8080/SDSService/rest/SDTMVariableInfoForDomainAndVersion/',$sdtmigversion,'/')
(: iterate over all dataset definitions of the general observation classes 'INTERVENTIONS', 'FINDINGS' and 'EVENTS :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='FINDINGS' or upper-case(@def:Class)='EVENTS']
    let $name := $itemgroupdef/@Name
    let $domainname := (    (: take the domain name either from the Domain attribute or the first 2 characters of the dataset name :)
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2)
    )
    (: iterate over all the variables and their names :)
    for $itemref in $itemgroupdef/odm:ItemRef
        let $varoid := $itemref/@ItemOID
        let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
        (: generate the RESTful web service query string :)
        let $webservicequery := concat($webservicebase,$domainname,'/',$varname)
        (: run the webservice: if the variable name is not allowed, the element XML4PharmaServerWebServiceResponse/Response does NOT contain a 'Variable' element :)
        let $webserviceresponsevariable := doc($webservicequery)/XML4PharmaServerWebServiceResponse/Response/Variable
        (: variable is not in the model :)
        where not($webserviceresponsevariable)
        return <error rule="CG0351" dataset="{data($name)}" sdtmigversion="{data($sdtmigversion)}" variable="{data($varname)}" rulelastupdate="2020-06-17">Variable '{data($varname)}' must be in a SUPPQUAL dataset as it is not in the SDTM model</error>			
	
	