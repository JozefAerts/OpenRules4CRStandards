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
Use the web service to find out - http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CDISCCoreFromSDTMVariable/{sdsVersion}/{domain}/{varName} :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM-IG version :)
(: TODO: for define.xml,get it at the dataset definition level :)
let $igversion := (
	if($defineversion = '2.1') then $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG'][1]/@Version
	else $definedoc//odm:MetaDataVersion/@def:StandardVersion
)
(: iterate over all datasets and variables in the define.xml :)
for $itemgroup in $definedoc//odm:ItemGroupDef
	let $itemgroupdefname := $itemgroup/@Name
	let $domain := $itemgroup/@Name
    (: get the dataset name and location :)
    let $datasetname := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    (: iterate over all ItemRef elements that hava Mandatory="No" :)
    for $itemref in $itemgroup/odm:ItemRef[@Mandatory='No']
        (: get the OID and the Name of the variable :)
        let $variableoid := $itemref/@ItemOID
        let $variablename := $definedoc//odm:ItemDef[@OID=$variableoid]/@Name
        (: invoke the webservice to find out whether the variable is permissible :)
        let $webservice := concat('http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CDISCCoreFromSDTMVariable/',$igversion,'/',$itemgroupdefname,'/',$variablename)
        let $webserviceresult := data(doc($webservice)/XML4PharmaServerWebServiceResponse/Response)  (: returns 'Req', 'Exp', or 'Perm' :)
        (: now take the dataset and count the number of data points for this variable :)
        let $count := count(doc($dataset)//odm:ItemGroupData/odm:ItemData[@ItemOID=$variableoid])
        (: no data points found :)
        where $webserviceresult='Perm' and $count = 0
        (: and give out an error message :)
        return <warning rule="SD1078" rulelastupdate="2020-08-08" dataset="{data($variablename)}" variable="{data($itemgroupdefname)}">Permissible variable {data($variablename)} has no values for all records in dataset {data($datasetname)}</warning>	
