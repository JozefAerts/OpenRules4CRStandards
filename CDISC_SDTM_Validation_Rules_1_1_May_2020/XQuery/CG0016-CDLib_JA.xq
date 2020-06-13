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

(: Rule CG0016: When Variable Core Status = Expected then Variable present in dataset  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $username external;
declare variable $password external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: Uses the CDISC library :)
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr'
(: the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM-IG version, we need to match it to the SDTM (model) version :)
let $sdtmigversiondefine := $definedoc//odm:MetaDataVersion/@def:StandardVersion
(: we need to translate the SDTM-IG version in what the CDISC library understands :)
let $sdtmigversion := translate($sdtmigversiondefine,'.','-')
(: iterate over all datasets except that belong to "General Observation" class :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef
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
    (: workaround for when @Domain is not populated :)
    let $domainname := (
    	if(string-length($domain)>0) then $domain
    	else $name
    )
    (: In order to limit the number of calls to the CDISC Library, 
    we ask for all the variables for the current class, 
    for which the response contains the "core" which can be "Exp" (expected) :)
    let $cdisclibraryquery := concat($cdisclibrarybase,'/sdtmig/',$sdtmigversion,'/classes/',$class)
    let $cdisclibraryresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquery) 
    (: get the CDISC library reponse limited to the current domain :)
    let $cdisclibrarydomain := $cdisclibraryresponse/json/datasets/*[name=$domainname]
    (: iterate over all the variables that are "expected" (core=Exp) :)
    for $expectedvarname in $cdisclibrarydomain//datasetVariables/*[core='Exp']/name
    (: now check whether the expected variable is in the define.xml for this domain :)
    	let $itemoid := (
    		for $a in $definedoc//odm:ItemDef[@Name=$expectedvarname]/@OID 
        		where $a = $dataset/odm:ItemRef/@ItemOID
        	return $a  
        )
        (: When not, give an error :)
        where not($itemoid) 
        return <error rule="CG0016" dataset="{$name}" variable="{$expectedvarname}" rulelastupdate="2020-06-11">Expected SDTM variable {data($expectedvarname)} is not found</error>
	
	