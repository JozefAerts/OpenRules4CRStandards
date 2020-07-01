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

(: Rule SD0058 - Variable appears in dataset, but is not in SDTM model :)
(: CDISC Library API Implementation :)
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
(: CDISC Library username and password :)
declare variable $username external;
declare variable $password external;
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: value-intersect function: returns the intersection of two sequences :)
declare function functx:value-intersect
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
  distinct-values($arg1[.=$arg2])
 } ;
(: combines two sequences :)
declare function functx:value-union
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
  distinct-values(($arg1, $arg2))
 } ;
(: function replacing two subsequent dashes with the domain code :)
declare function local:replacedash($sequence,$domain) {
    for $v in $sequence
            return replace($v,'\-\-',$domain)
} ;
(: let $base := 'SEND_3_0_PC201708/'  :)
(: let $define := 'define.xml' :)
let $definedoc := doc(concat($base,$define))
(: Translate the SEND-IG version to an SDTM MODEL version :)
let $sendigversion := $definedoc//odm:MetaDataVersion/@def:StandardVersion
let $sdtmversion := (
	if($sendigversion = '3.0') then '1-2'
	else if($sendigversion = '3.1') then '1-5'
    else 'unknown'
)
(: CDISC-Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: In order to avoid too many calls to the CDISC Library, 
we already generate a list of all "General Observations" variables :)
(: e.g.: https://library.cdisc.org/api/mdr/sdtm/1-2/classes/GeneralObservations :)
let $cdisclibrarygeneralobservationsquery := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/GeneralObservations')
let $cdisclibrarygeneralobservationsresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibrarygeneralobservationsquery)
(: In order to minimize the number of calls to the CDISC Library,
we group all dataset definition by def:Class :)
(: Order all dataset definitions per def:Class,
so that we need only 1 CDISC-Library call per class :)
let $groupeditemgroupdefs := (
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
	let $defclass := $group/odm:ItemGroupDef[1]/@def:Class
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
    let $cdisclibraryquerysdtmmodel := concat($cdisclibrarybase,'sdtm/',$sdtmversion,'/classes/',$class)
    (: now run the CDISC Library query
       as it requires basic authentication, 
       we need to use the EXPath 'http-client' extension :)
    let $cdisclibraryresponsesdtmmodel := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmmodel)
    (: iterate over the datasets in the group - each of them has the same def:Class value :)
    for $itemgroupdef in $group/odm:ItemGroupDef
    	(: get the name of the dataset and the domain :)
        let $name := $itemgroupdef/@Name
        let $domainname := $itemgroupdef/@Domain
        (: iterate over all variables within the dataset definition :)
        for $itemrefoid in $itemgroupdef/odm:ItemRef/@ItemOID
        	let $varname := $definedoc//odm:ItemDef[@OID=$itemrefoid]/@Name 
            (: we need to take generic variable names into account, 
              e.g. LBDTC goes into --DTC :)
            let $varnamegen := (
                if(starts-with($varname,$domainname)) 
                    then concat('--',substring($varname,3))
                else $varname
            )
            (: now look up the variable name in the SDTM model for this class :)
            let $cdisclibraryvar := (
            	if($class = 'Interventions' or $class='Events' or $class='Findings') then 
            		$cdisclibraryresponsesdtmmodel/json//classVariables/*[name=$varname or name=$varnamegen]
                else  $cdisclibraryresponsesdtmmodel/json//datasetVariables/*[name=$varname or name=$varnamegen]
            )(: and in the "General Observations Class" :)
            let $cdisclibrarygeneralvar := $cdisclibrarygeneralobservationsresponse/json//classVariables/*[name=$varname or name=$varnamegen]
            let $varnamereport := (
            	if(starts-with($varname,$domainname)) then $varnamegen
                else $varname
            )
            where not($cdisclibraryvar) and not($cdisclibrarygeneralvar)
            return <error rule="SE0058" dataset="{data($name)}" rulelastupdate="2020-06-26">Variable '{data($varnamereport)}' is not in SDTM Model version {data($sdtmversion)}</error>
