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

(: Rule SD1078 - Permissible variable with missing value for all records:
Permissible variable whould not be present in domain, when the variable has missing value for all records in the dataset :)
(:  How do we know that a variable is permissible? Mandatory="No" is essentially not sufficient. 
Implementation using the CDISC Library :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
declare variable $username external;
declare variable $password external;
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
(: let $datasetname := 'DM' :)
let $definedoc := doc(concat($base,$define))
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: get the SEND-IG version :)
let $sendigversion := $definedoc//odm:MetaDataVersion/@def:StandardVersion
(: Translate the IG version to one the CDISC library understands: 
replace dot by dash :)
let $sendigversion := translate($sendigversion,'.','-') 
(: iterate over the provided dataset(s) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
	let $defclass := $itemgroupdef/@def:Class
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
    (: Make the CDISC Library call to get all variable information per domain for this class  :)
    let $cdisclibraryquerysendig := concat($cdisclibrarybase,'sendig/',$sendigversion,'/classes/',$class)	
    let $cdisclibraryresponsesendig := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysendig)
      (: get name, domain :)
      let $name := $itemgroupdef/@Name
      let $domainname := (
      	if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else if (starts-with($name,'SUPP')) then 'SUPPQUAL'
        else if ($name='POOLDEF') then 'POOLDEF'
        else if ($name='RELREC') then 'RELREC'
        else substring($name,1,2)
      )
      (: get the location of the dataset and the document itself :)
      let $dsloc := $itemgroupdef/def:leaf/@xlink:href
      let $doc := (
      	if($dsloc) then doc(concat($base,$dsloc))
        else () (: no location defined :)
      )
      (: Iterate over all the variables in the dataset definition :)
      for $itemoid in $itemgroupdef/odm:ItemRef/@ItemOID
        let $varname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
        (: Get the "core" property - can be "Req", "Exp" or "Perm" :)
        let $core := ($cdisclibraryresponsesendig/json/datasets/*[name=$domainname]//*[./name=$varname]/core/text())
        (: return <test>{data($domainname)} - {data($varname)} - {$core}</test>  :)
        (: in case a variable is not explicitely mentioned in the SEND-IG), 
        it is always permissible 'Perm' :)
        let $core := (
        	if(not($core)) then 'Perm'
        	else $core
        ) 
        (: count the number of records in the dataset for the "Perm" variables :)
        (: if the variable is NOT 'Perm' we set the count artficially to 1
        so that the system does not need to go over all the records, which saves time :)
        let $count := (
        	if(not($core='Perm')) then 1
        	else count($doc//odm:ItemGroupData/odm:ItemData[@ItemOID=$itemoid and @Value])
        )
        where $core='Perm' and $count=0
        return <warning rule="SD1078" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2020-06-27">Permissible variable {data($varname)} with missing value for all records</warning>
