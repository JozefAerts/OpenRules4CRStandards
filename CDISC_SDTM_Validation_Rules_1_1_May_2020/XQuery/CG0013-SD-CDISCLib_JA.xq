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

(: Rule CG0013: Variable = Model List of Allowed Variables for Observation Class  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: CDISC Library username and password :)
declare variable $username external;
declare variable $password external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: Uses the CDISC library, e.g. query
https://library.cdisc.org/api/mdr/sdtm/1-7/classes/GeneralObservations/variables/--NOMDY
:)
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM-IG version, we need to match it to the SDTM (model) version :)
let $sdtmigversion := $definedoc//odm:MetaDataVersion/@def:StandardVersion
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
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    let $domain := $dataset/@Domain
    let $defclass := $dataset/@def:Class
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
    (: iterate over the defined variables (by OID) and then name :)
    (: but ONLY when we are in a "General Observation" class  :)
    for $varoid in $dataset/odm:ItemRef/@ItemOID[$class='Findings' or $class='Events' or $class='Interventions' or $class='FindingsAbout']
    	let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
        (: workaround for when the Domain attribute is not populated
        which we see a lot in older define.xml files :)
        let $domainname := (
        	if(string-length($domain)>0) then $domain
            else $name
        )
        (: we need to take generic variable names into account, 
        	e.g. LBDTC goes into --DTC :)
        let $varnamegen := (
        	if(starts-with($varname,$domainname)) 
            	then concat('--',substring($varname,3))
            else $varname
        )
        (: when not found, it needs to be looked up in the IG :)
        where not($cdisclibrarysdtmmodelresponse/json//*[name=$varnamegen]) and not($cdisclibrarysdtmgeneralresponse/json//*[name=$varnamegen])
        return <error rule="CG0013" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2020-06-11">Variable {data($varname)} is not in the model list of allowed variables for class {data($class)}</error>
	