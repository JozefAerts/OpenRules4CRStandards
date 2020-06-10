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

(: Rule CG0303 - Variable Label = IG Label :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: the base of the webservice :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/SDTMVariableInfoForDomainAndVersion/3.2/'
(: iterate over all datasets in the define.xml :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    (: get the name of the dataset :)
    let $name := $itemgroupdef/@Name
    (: get the domain of the dataset :)
    let $domain := $itemgroupdef/@Domain
    (: sometimes the domain is not provided explicetly, 
    then we need to retrieve it from the dataset name.
    We however also need to take care of 'splitted' datasets, so we take the first two characters
    except for SUPPxx datasets for which we set 'SUPPQUAL' :)
    let $domain := (
        if(not($domain) and not(starts-with($name,'SUPP')) and not($name='RELREC')) then substring($name,1,2)
        else if (starts-with($name,'SUPP')) then 'SUPPQUAL'
        else if (not ($domain)) then $name
        else $name
    )
    (: iterate over all the variable OIDs in the dataset definition :)
    for $itemoid in $itemgroupdef/odm:ItemRef/@ItemOID
        (: look up the variable name :)
        let $varname := $definedoc//odm:ItemDef[@OID=$itemoid]/@Name
        (: and the given label :)
        let $label := $definedoc//odm:ItemDef[@OID=$itemoid]/odm:Description/odm:TranslatedText[1]
        (: get the formal label from the web service - first generate the query :)
        let $webservicerequest := concat($webservicebase,$domain,'/',$varname)
        (: now get the label from the webservice response from 
        XML4PharmaServerWebServiceResponse/Response/Variable/Variable_Label :)
        let $labelfromwebservice := doc($webservicerequest)/XML4PharmaServerWebServiceResponse/Response/Variable/Variable_Label 
        (: sometimes there is no label from the SDTM-IG, as the variable is not mentioned in the IG (e.g. additional timing variable), 
        or that the variable is a non-standard variable (NSV), which however should normally go into SUPPQUAL :)
        where $labelfromwebservice and not($labelfromwebservice=$label)
        return <error rule="CG0303" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2017-03-05">
            Label '{data($label)}' does not correspond to the expected label from the SDTM-IG '{data($labelfromwebservice)}' </error>			
		
		