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

(: Rule CG0400 - --LOINC = valid code in the version of the LOINC dictionary specified in define.xml :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/LZZT_2013_LBLOINC/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: the base of the XML4PharmaServer web service - see http://xml4pharmaserver.com/WebServices/LOINC_webservices.html :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/LOINCService/rest/LOINCName/'
(: iterate over all the FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $itemgroupdef/@Name
    let $domainname := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($itemgroupdef/@Name,1,2)
    )
    (: get the OID of --LOINC :)
    let $loincoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'LOINC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the full name :)
    let $loincname := $definedoc//odm:ItemDef[@OID=$loincoid]/@Name
    (: get the dataset location and document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all the records in the dataset for which --LOINC is populated :)
    (: in order to reduce the number of web services requests, first group the records by LOINC code :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$loincoid]]
            group by 
            $b := $record/odm:ItemData[@ItemOID=$loincoid]/@Value
            return element group {  
                $record
            }
        )
    (: iterate over all groups - in each group, the --LOINC value is identical for all the records :)
    for $group in $orderedrecords
        (: get the LOINC value of the first record :)
        let $loinc := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$loincoid]/@Value
        (: create the webservice query string :)
        let $webservicequery := concat($webservicebase,$loinc)
        (: submit the XML4PharmaServer web service, it returns a XML4PharmaServerWebServiceRespons/Response XML structure :)
        let $webserviceresponse := doc($webservicequery)/XML4PharmaServerWebServiceResponse/Response
        (: in case the LOINC code is invalid, the text content of "Response" is "null" (as a text). In such a case, iterate over all the records in the group,
        and produce an error message :)
        (: return <test code="{data($loinc)}">{data($webserviceresponse)}</test> :)
        let $errormessages := 
            if($webserviceresponse='null' or string-length($webserviceresponse)=0) then
                for $record in $group/odm:ItemGroupData
                let $recnum := $record/@data:ItemGroupDataSeq
                return <error rule="CG0400" dataset="{data($name)}" recordnumber="{data($recnum)}" variable="{data($loincname)}" rulelastupdate="2020-08-04">LOINC code for {data($loincname)}='{data($loinc)}' is not recognized as a valid LOINC code by the XML4Pharma RESTful web service</error> 
            else ()  
        return $errormessages	
		
	