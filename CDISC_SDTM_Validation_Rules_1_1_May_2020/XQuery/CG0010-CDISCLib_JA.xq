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

xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
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
let $sdtmigversion := translate($sdtmigversion,'.','-')
(: iterate over all datasets except that belong to "General Observation" class :)
for $dataset in $definedoc//odm:ItemGroupDef
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
    (: workaround for when the Domain attribute is not populated
        which we see a lot in older define.xml files :)
    let $domainname := (
    	if(string-length($domain)>0) then $domain
        else $name
    )
    (: as "Role" is already provided in the CDISC Library response at the "Class" level, 
    (except for e.g. timing variables)
    do the call to the CDISC Library BEFORE iterating over the variables :)
    (: iterate over the defined variables (by OID) and then name :)
    (: but ONLY when we are in a "General Observation" class  :)
    (: CDISC Library query to the SDTM MODEL :)
    let $cdisclibraryquerysdtmmodel := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/',$class)	
     (: now run the CDISC Library query
     as it requires basic authentication, 
     we need to use the EXPath 'http-client' extension :)
    let $cdisclibraryresponsesdtmmodel := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmmodel)
    (: CDISC Library query to the SDTM-IG :)
    let $cdisclibraryquerysdtmig := concat($cdisclibrarybase,'sdtmig/',$sdtmigversion,'/classes/',$class)	
    let $cdisclibraryresponsesdtmig := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmig)
   	for $var in $dataset/odm:ItemRef[$class='Findings' or $class='Events' or $class='Interventions' or $class='FindingsAbout']
    	let $varoid := $var/@ItemOID
        let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
        let $roledefinexml := $var/@Role  (: could however be absent :)
        (: we need to take generic variable names into account, 
        	e.g. LBDTC goes into --DTC :)
        let $varnamegen := (
        	if(starts-with($varname,$domainname)) 
            	then concat('--',substring($varname,3))
            else $varname
        )
        let $roleexpectedsdtmmodel := $cdisclibraryresponsesdtmmodel/json//*/role[../name=$varname or ../name=$varnamegen]
        (: Take care: e.g. VISITNUM can occur several times :)
        let $roleexpectedsdtmig := ($cdisclibraryresponsesdtmig/json//*/role[../name=$varname or ../name=$varnamegen])[1]
        (: return <test>{data($varname)} - {data($roleexpectedsdtmig)} - {data($roleexpectedsdtmmodel)}</test> :)
        (: compare the Role from the define.xml with the expected one, 
        allow case-insensitive :)
        let $roleexpected := (
        	if($roleexpectedsdtmmodel) then data($roleexpectedsdtmmodel)
            else data($roleexpectedsdtmig)
        )
        where $roledefinexml and $roleexpected and not(upper-case($roledefinexml)=upper-case($roleexpectedsdtmmodel)) and not(upper-case($roledefinexml)=upper-case($roleexpectedsdtmig))
        return <error rule="CG0010" variable="{data($varname)}" dataset="{data($name)}" class="{data($class)}" rulelastupdate="2020-06-10">Variable Role found: '{data($roledefinexml)}' - Role expected: '{$roleexpected}'</error>		
	
	