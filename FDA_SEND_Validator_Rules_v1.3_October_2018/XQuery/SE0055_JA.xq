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
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: CDISC Library username and password :)
declare variable $username external;
declare variable $password external;
(: let $base := 'SEND_3_0_PC201708/'  :)
(: let $define := 'define.xml' :)
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
(: Uses the CDISC library, e.g. query
https://library.cdisc.org/api/mdr/sdtm/1-7/classes/GeneralObservations/variables/--NOMDY
:)
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SEND-IG version, we need to match it to the SDTM (model) version :)
let $sendigversion := $definedoc//odm:MetaDataVersion/@def:StandardVersion
let $sdtmversion := (
	if($sendigversion = '3.0') then '1-2'
	else if($sendigversion = '3.1') then '1-5'
    else 'unknown'
)
(: Replace dot by dash for SEND-IG version for use in CDISC Library :)
let $sendigversion := translate($sendigversion,'.','-')
(: Order all dataset definitions per def:Class,
so that we need only 1 CDISC-Library call per class :)
let $groupeditemgroupdefs := (
	if($defineversion = '2.1') then 
		for $itemgroup in $definedoc//odm:ItemGroupDef
				group by 
				$a := $itemgroup/def21:Class/@Name
				return element group {  
					$itemgroup
				}
	else 
		for $itemgroup in $definedoc//odm:ItemGroupDef
				group by 
				$a := $itemgroup/@def:Class
				return element group {  
					$itemgroup
				}
)
(: iterate over the groups - 
in each group, all dataset definitions (ItemGroupDef) have the same value for def:Class :)
for $group in $groupeditemgroupdefs
	let $defclass := (
		if($defineversion='2.1') then $group/odm:ItemGroupDef[1]/def21:Class/@Name
		else $group/odm:ItemGroupDef[1]/@def:Class
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
    (: CDISC Library query to the SDTM MODEL :)
    (: let $cdisclibraryquerysdtmmodel := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/',$class)	:)
    (: now run the CDISC Library query
       as it requires basic authentication, 
       we need to use the EXPath 'http-client' extension :)
    (: let $cdisclibraryresponsesdtmmodel := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmmodel):)
    (: CDISC Library query to the SEND-IG :)
    let $cdisclibraryquerysendig := concat($cdisclibrarybase,'sendig/',$sendigversion,'/classes/',$class)	
    let $cdisclibraryresponsesendig := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysendig)
  	(: Iterate over all dataset definitions :)
  	for $itemgroupdef in $group/odm:ItemGroupDef
      (: get name, domain and class :)
      let $name := $itemgroupdef/@Name
      let $domainname := $itemgroupdef/@Domain
      (: iterate over all variables within the domain :)
      for $itemrefoid in $itemgroupdef/odm:ItemRef/@ItemOID
          let $varname := $definedoc//odm:ItemDef[@OID=$itemrefoid]/@Name
          (: we need to take generic variable names into account, 
              e.g. LBDTC goes into --DTC :)
          let $varnamegen := (
              if(starts-with($varname,$domainname)) 
                  then concat('--',substring($varname,3))
              else $varname
          )
          let $definedatatype := $definedoc//odm:ItemDef[@OID=$itemrefoid]/@DataType
          (: look up the name in the CDISC Library response and get the XPT simple datatype :)
          let $simpledatatype := ($cdisclibraryresponsesendig/json//*/simpleDatatype[../name=$varname or ../name=$varnamegen])[1]
          (: When the simple datatype is 'Num', we require Define-XML datatype 'integer', 'float' or 'double' :)
          (: When the simple datatype is 'Char', we require Define-XML datatype NOT to be 'integer', 'float' or 'double' :)
          where ($simpledatatype = 'Num' and not($definedatatype='integer' or $definedatatype='float' or $definedatatype='double'))
              or ($simpledatatype = 'Char' and ($definedatatype='integer' or $definedatatype='float' or $definedatatype='double')) 
          return <error rule="SE0055" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2020-06-26">Dataset datatype '{data($definedatatype)}' does not correspond to expected SEND-IG datatype '{data($simpledatatype)}'</error> 

