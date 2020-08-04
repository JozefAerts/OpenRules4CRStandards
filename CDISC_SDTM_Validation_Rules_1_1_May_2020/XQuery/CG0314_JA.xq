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

(: Rule CG0314 - When SUPP--.QNAM present in dataset then Value of SUPP--.QNAM != any variable name defined in the corresponding SDTM version :)
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
let $definedoc := doc(concat($base,$define)) 
(: Get the version of the SDTM-IG, and derive the SDTM Model version from it:
SDTM-IG 3.1.2 => SDTM 1.2
SDTM-IG 3.1.3 => SDTM 1.3
SDTM-IG 3.2 => SDTM 1.4 (default)
SDTM-IG 3.3 => SDTM 1.7 :)
(: TODO: for define.xml 2.1, pick up the version at the ItemGroupDef level :)
let $sdtmigversion := (
	if($defineversion='2.1') then $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG' and @Name='SDTMIG']/@Version
	else $definedoc//odm:MetaDataVersion[@def:StandardName='SDTM-IG']/@def:StandardVersion 
)
let $sdtmmodelversion := (
	if($sdtmigversion='3.1.2') then '1.2'
	else if($sdtmigversion = '3.1.3') then '1.3'
    else if($sdtmigversion = '3.2') then '1.4'
    else if($sdtmigversion = '3.3') then '1.7'
    else '1.4'
)
(: The base of the RESTful web service  :)
let $webservicebase := concat('http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/SDSVariableInfo/',$sdtmmodelversion,'/')
(: iterate over all SUPPxx datasets definitions  :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $itemgroupdef/@Name
    (: we need the OID of QNAM and of RDOMAIN :)
    let $qnamoid := (
        for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all the records in the datasset
    ALTERNATIVE: get all unique values of QNAM in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of QNAM :)
        let $qnam := $record/odm:ItemData[@ItemOID=$qnamoid]/@Value
        (: get the related domain (RDOMAIN) :)
        let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        (: invoke the RESTful web service to see whether this variable is already known (reserved) for this domain :)
        let $webservicerequest := concat($webservicebase,$qnam)
        (: run the webservice and get the variable from the response. If the QNAM is allowed, the response <Variable> element has no child elements, 
        and thus also no label :)
        let $varlabelsdtm := doc($webservicerequest)/XML4PharmaServerWebServiceResponse/Response/Variable/Variable_Label
        (: is there IS a variable label for this variable, then the value of QNAM is already defined in SDTM, and the rule is violated :)
        where $varlabelsdtm
        return <error rule="CG0314" sdtmigversion="{data($sdtmigversion)}" dataset="{data($name)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">The value of QNAM='{data($qnam)}' is not allowed as it is already defined in SDTM</error>								
	
	