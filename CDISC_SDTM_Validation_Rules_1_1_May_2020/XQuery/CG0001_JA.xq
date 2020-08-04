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

(: Rule CG0001: DOMAIN = valid Domain Code published by CDISC, with exception of custom domains :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: Uses the XML4Pharma RESTful web service for SDTM domains :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/CDISCDomainService/rest/StandardNameAndVersionFromDomainName/' 
(: get the standard name and SDTM-IG version :)
let $definedoc := doc(concat($base,$define))
(: Do on ItemGroupDef level for define.xml 2.1 :)
(: Remark that $standardname is not further used in the RESTful-WS query itself :)
let $standardname := (
	if($defineversion = '2.1') then $definedoc//odm:MetaDataVersion[1]/def21:Standards/def21:Standard[@Type='IG']/@Name
	else $definedoc//odm:MetaDataVersion[1]/@def:StandardName
)
let $standardversion := (
	if($defineversion = '2.1') then $definedoc//odm:MetaDataVersion[1]/def21:Standards/def21:Standard[@Name=$standardname]/@Version
	else $definedoc//odm:MetaDataVersion[1]/@def:StandardVersion
)
(: iterate over the dataset definitions that are according to SDTM-IG v.3.2 :)
for $dataset in $definedoc//odm:ItemGroupDef
   (: get the location of the file :)
   let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
   let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
   )
   (: get the OID of the "DOMAIN" variable :)
   let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
   )
   (: get the unique values of variable DOMAIN in the dataset :)
   let $uniquedomainvalues := distinct-values($datasetdoc//odm:ItemData[@ItemOID=$domainoid]/@Value)
   for $domainvalue in $uniquedomainvalues
   		let $webserviceresponse := concat($webservicebase,$domainvalue,'.xml') (: enforce XML :)
   		let $domainsupported := doc($webserviceresponse)//standard[@name='SDTM' and @version=$standardversion]
   		where not($domainsupported)
   		return <warning rule="CG0001" dataset="{data($name)}" rulelastupdate="2020-08-04">Domain code '{data($name)}' is not a valid domain code for CDISC SDTM version '{data($standardversion)}'</warning>	
            
        