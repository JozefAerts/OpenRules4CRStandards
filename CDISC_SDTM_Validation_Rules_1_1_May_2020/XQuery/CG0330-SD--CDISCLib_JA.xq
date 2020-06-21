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

(: Rule CDG0330 - Variable is in wrong order within domain: Order of variables should be as specified by CDISC standard
We must look into the SDTM specification itself, make a list (how do we deal with prefixes?) and then compare the list with the order in the define.xml.
Is it also possible (in a second step?) to compare the order of the variables in each record with that in the define.xml?
:)	
(: Single dataset version :)
(: The current version uses the CDISC Library and its API :)
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
declare variable $datasetname external;
(: CDISC Library API username and password :)
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
 
 (: This function compares two sequences in which the second is a subset of the first.
 If the order in both is the same, the function returns 'true', if the order is different, it returns 'false' :)
 declare function local:compare($sequence1, $sequence2) {
    let $new-list :=
      for $id in $sequence1
      where $id = $sequence2
      return $id
    return string-join($sequence2,'') eq string-join($new-list, '')
} ;
(: function replacing two subsequent dashes with the domain code :)
declare function local:replacedash($sequence,$domain) {
    for $v in $sequence
            return replace($v,'\-\-',$domain)
} ;
(: let username := 'xxxx' :)
(: let $password := 'yyyy' :)
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: get the define.xml :)
let $definedoc := doc(concat($base,$define))
(: Get the SDTM-IG version, taking '3.2' as the default :)
let $sdtmigversion := (
	if($definedoc//odm:MetaDataVersion[@StandardName='SDTM-IG']/@StandardVersion) then $definedoc//odm:MetaDataVersion[@StandardName='SDTM-IG']/@StandardVersion
	else '3.2'
)
(: Translate the SDTM-IG version into the SDTM model version, with '1.4' as the default, :)
let $sdtmmodelversion := (
	if($sdtmigversion='3.1.2') then '1.2'
	else if($sdtmigversion = '3.1.3') then '1.3'
    else if($sdtmigversion = '3.2') then '1.4'
    else if($sdtmigversion = '3.3') then '1.7'
    else '1.4'
)
(: Replacing the dot by a dash as the CDISC Library uses the latter :)
let $sdtmmodelversioncdisclibrary := translate($sdtmmodelversion,'.','-')
(: Use the CDISC Library to get all Identifiers and Timing variables for all classes :)
let $cdisclibrarybase := concat('https://library.cdisc.org/api/mdr/sdtm/',$sdtmmodelversioncdisclibrary,'/classes/')
let $identifierstimingsquery := concat($cdisclibrarybase,'GeneralObservations')
let $identifierstimingsresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $identifierstimingsquery)
(: we need to split identifiers and timing variable :)
let $identifiers := $identifierstimingsresponse/json//classVariables/*[role='Identifier']/name/text()
let $timings := $identifierstimingsresponse/json//classVariables/*[role='Timing']/name/text()
(: Use the CDISC Library to get all Interventions variables :)
let $interventionsquery := concat($cdisclibrarybase,'Interventions')
let $interventionsresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $interventionsquery)
let $interventions := $interventionsresponse/json//classVariables/*/name/text()
(: Use the CDISC Library to get all Events variables :)
let $eventsquery := concat($cdisclibrarybase,'Events')
let $eventsresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $eventsquery)
let $events := $eventsresponse/json//classVariables/*/name/text()
(: Use the CDISC Library to get all Events variables :)
let $findingsquery := concat($cdisclibrarybase,'Findings')
let $findingsesponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $findingsquery)
let $findings := $findingsesponse/json//classVariables/*/name/text()
(: Use the CDISC Library to get all FindingsAbout variables :)
let $findingsaboutquery := concat($cdisclibrarybase,'FindingsAbout')
let $findingsaboutresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $findingsaboutquery)
let $findingsabout := $findingsaboutresponse/json//classVariables/*/name/text()
(: Use the CDISC Library to get all SpecialPurpose variables :)
(: ATTENTION: these are organized per dataset! :)
let $specialpurposequery := concat($cdisclibrarybase,'SpecialPurpose')
let $specialpurposeresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $specialpurposequery)
let $specialpurpose := $specialpurposeresponse/json//datasets
(: Use the CDISC Library to get all TrialDesign variables :)
(: ATTENTION: these are organized per dataset! :)
let $trialdesignquery := concat($cdisclibrarybase,'TrialDesign')
let $trialdesignresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $trialdesignquery)
(: Remark that we do NOT go into the individual datasets YET :) 
let $trialdesign := $trialdesignresponse/json//datasets
(: Use the CDISC Library to get all TrialDesign variables :)
(: ATTENTION: these are organized per dataset! :)
let $relastionshipquery := concat($cdisclibrarybase,'Relationship')
let $relationshipresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $relastionshipquery)
let $relationship := $relationshipresponse/json//datasets
(: Use the CDISC Library to get all AssociatedPersons variables :)
let $associatedpersonsquery := concat($cdisclibrarybase,'AssociatedPersons')
let $associatedpersonsresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $associatedpersonsquery)
let $associatedpersonsclassVariables := $associatedpersonsresponse/json//classVariables/*/name/text()
let $associatedpersonsdatasetVariables := $associatedpersonsresponse/json//datasetVariables/*/name/text()
(: iterate over the provided dataset definitions, and get the class, name and domain :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
	let $defclass := $itemgroupdef/@def:Class
    let $name := $itemgroupdef/@Name
    let $domain := (
    	if(starts-with($name,'SUPP')) then 'SUPPQUAL'
    	else if($itemgroupdef/@Domain) then @Domain
        else if($itemgroupdef/@Name='RELREC') then 'RELREC'
        else substring($itemgroupdef/@Name,1,2)
    )
   (: get the variable name :)
    let $variables := (
    	for $varoid in $itemgroupdef/odm:ItemRef/@ItemOID 
        return $definedoc//odm:ItemDef[@OID=$varoid]/@Name
    )
    (: now comes the different part: check the order :)
    (: depending on the class, create an ordered array of the variables that are applicable :)
    let $orderedvariables := (
    	if(upper-case($defclass)='INTERVENTIONS') then
         	functx:value-union(functx:value-union($identifiers,$interventions),$timings)
        else if(upper-case($defclass)='EVENTS') then
         	functx:value-union(functx:value-union($identifiers,$events),$timings)
        else if(upper-case($defclass)='FINDINGS') then    
        	functx:value-union(functx:value-union($identifiers,$findings),$timings)
        else if(upper-case($defclass)='TRIALDESIGN' or upper-case($defclass)='TRIAL DESIGN') then
        	$trialdesign/*[./name=$domain]/datasetVariables/*/name
        else if(upper-case($defclass)='RELATIONSHIP') then
        	$relationship/*[./name=$domain]/datasetVariables/*/name
        else if(upper-case($defclass)='SPECIAL PURPOSE' or upper-case($defclass)='SPECIALPURPOSE') then
        	$specialpurpose/*[./name=$domain]/datasetVariables/*/name
    )
    (: we need to replace '--' by the domain name :)
    let $orderedvars := local:replacedash($orderedvariables,$domain)
    (: check whether the variables from the define.xml is a subset of the list of domain variables  :)
    let $issubset := local:compare($orderedvars,$variables) 
    where not($issubset)
    return <error rule="CG0330" dataset="{data($name)}" class="{data($defclass)}" sdtmigversion="{data($sdtmigversion)}" rulelastupdate="2020-06-16">Variable order is not correct: found = {data($variables)} - expected = {$orderedvars}</error>	
	
	