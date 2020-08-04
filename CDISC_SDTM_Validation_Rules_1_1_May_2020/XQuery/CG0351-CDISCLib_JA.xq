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
(: CDISC Library username and password :)
declare variable $username external;
declare variable $password external;
(: let $base := 'MSG_draft_define_2-1/' :)
(: let $define := 'define_2_1.xml' :)
(: let $defineversion := '2.1' :)
(: let $username := 'xxxx' :)
(: let $password := 'yyyy' :)
(: Uses the CDISC library, e.g. query
https://library.cdisc.org/api/mdr/sdtm/1-7/classes/GeneralObservations/variables/--NOMDY
:)
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM-IG version, we need to match it to the SDTM (model) version :)
(: Get the SDTM-IG version from the define.xml (default "3.2" :)
let $sdtmigversion := (
	if ($defineversion='2.0' and $definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']) 
		then $definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']/@def:StandardVersion
	else if ($defineversion='2.1' and $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG' and @Name='SDTMIG']) 
		then $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG' and @Name='SDTMIG']/@Version
    else '3.2'
)
let $sdtmversion := (
	if($sdtmigversion = '3.1.2') then '1-2'
	else if($sdtmigversion = '3.1.3') then '1-3'
    else if($sdtmigversion = '3.2') then '1-4'
    else if($sdtmigversion = '3.3') then '1-7'
    else 'unknown'
)
(: also for the IG, we need to replace the dot by a dash :)
let $sdtmigversion := translate($sdtmigversion,'.','-')
(: iterate over all datasets except that belong to "General Observation" class :)
(: iterate over all dataset definitions of the general observation classes 'INTERVENTIONS', 'FINDINGS' and 'EVENTS' :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='FINDINGS' or upper-case(@def:Class)='EVENTS' 
	or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='FINDINGS' or upper-case(./def21:Class/@Name)='EVENTS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    (: let $datasetlocation := concat($base,$datasetname) :)
    let $domainname := (    (: take the domain name either from the Domain attribute or the first 2 characters of the dataset name :)
        if($dataset/@Domain) then $dataset/@Domain
        else substring($name,1,2)
    )
    let $defclass := (
		if($defineversion='2.1') then $dataset/def21:Class/@Name
		else $dataset/@def:Class
	)
    (: Unfortunately, the way of writing the class name (casing)
    has not always been consistent within CDISC :)
    let $class := (
    	if(upper-case($defclass)= 'FINDINGS') then 'Findings'
		else if (upper-case($defclass)= 'EVENTS') then 'Events'
        else if (upper-case($defclass)= 'INTERVENTIONS') then 'Interventions'
        else if (starts-with(upper-case($defclass),'TRIAL')) then 'TrialDesign'
        else if (ends-with(upper-case($defclass),'ABOUT')) then 'FindingsAbout'
        else if (starts-with(upper-case($defclass),'SPECIAL')) then 'SpecialPurpose'
        else if (starts-with(upper-case($defclass),'RELAT')) then 'Relationship'
        else 'GeneralObservations'
    )
    (: construct the CDISC Library query 
    important: "generic" variables NOT starting with --
    need to be looked up as "GeneralObservations",
    Except for "trial design" and "special purpose" :)
    let $cdisclibraryquerysdtmmodel := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/',$class)
    (: now run the CDISC Library query
        as it requires basic authenticatio, 
        we need to use the EXPath 'http-client' extension :)
    let $cdisclibrarysdtmmodelresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmmodel)
    (: we will also need to look into the 'GeneralObservations' itself :)
    let $cdisclibraryquerysdtmgeneral := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/GeneralObservations')
    let $cdisclibrarysdtmgeneralresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmgeneral)
    (: TODO: for SDTM-IG 3.3, there are "Domain-Specific Variables for the General Observation Classes" :)
    (: MHEVDTYP, EXMETHOD, EGBEATNO, ICIMPLBL, MSAGENT, MSCONC, MSCONCU :)
    let $domainspecific_3_3_variables := (
    	if($sdtmigversion = '3-3') then ('MHEVDTYP', 'EXMETHOD', 'EGBEATNO', 'ICIMPLBL', 'MSAGENT', 'MSCONC', 'MSCONCU')
        else ()
    )
    (: iterate over the defined variables (by OID) and then name :)
    (: but ONLY when we are in a "General Observation" class  :)
    for $varoid in $dataset/odm:ItemRef/@ItemOID[$class='Findings' or $class='Events' or $class='Interventions' or $class='FindingsAbout']
    	let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
        (: we need to take generic variable names into account, 
        	e.g. LBDTC goes into --DTC :)
        let $varnamegen := (
        	if(starts-with($varname,$domainname)) 
            	then concat('--',substring($varname,3))
            else $varname
        )
        (: when not found, it needs to be looked up in the GeneralObservations :)
        where not(functx:is-value-in-sequence($varname,$domainspecific_3_3_variables)) and not($cdisclibrarysdtmmodelresponse/json//*[name=$varnamegen]) and not($cdisclibrarysdtmgeneralresponse/json//*[name=$varnamegen])
        return <error rule="CG0351" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2020-08-04">Variable {data($varname)} is not in the model list of allowed variables for class {data($class)} and must go into SUPPQUAL</error>
	
	