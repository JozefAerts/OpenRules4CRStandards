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

(: REQUIRES XQuery 3.1 ! :)
xquery version "3.1";
(: Rule SD1322: Value for COUNTRY (DM) must be found in ISO 3166 :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: declare variable $domain external; :)
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml'  :)
let $definedoc := doc(concat($base,$define))
(: get the metadata for the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: get the OID of the "COUNTRY" variable :)
let $countryoid := (
    for $a in $definedoc//odm:ItemDef[@Name='COUNTRY']/@OID 
        where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: get the location of the DM dataset and the document itself :)
let $datasetlocation := (
	if($defineversion = '2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
	else $dmitemgroupdef/def:leaf/@xlink:href
)
(: group the records by "COUNTRY".
 This enables to call the RESTful web service (the slowest step) only once per group/country :)
let $orderedrecords := (
        for $record in doc(concat($base,$datasetlocation))//odm:ItemGroupData[odm:ItemData[@ItemOID=$countryoid]]
            group by 
            $b:=$record/odm:ItemData[@ItemOID=$countryoid]/@Value
            return element group {  
                $record
            }
        )
(: Iterate over the groups, we only need to check the first record in the group,
 as all the records in each group have the same value for COUNTRY :)
for $group in $orderedrecords
    let $country := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$countryoid]/@Value
    let $recnum :=  $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq  (: first record number in the group :)
    (: now call the RESTful web service to check the validity of the country code :)
    let $querystring := concat('https://restcountries.eu/rest/v2/alpha/',$country)
    (: submit the country code and ask up it's alpha-3 code.
    If the request fails (not a 200 code), generate the string 'error'
    :)
    let $response := 
    try {
        json-doc($querystring)?alpha3Code
    } catch * {
        'error'
    }
    (: the alpha-3 code returned from the service must map the one provided
    when not, the code was not found :)
    where not($response = $country)
    return <error rule="SD1322" dataset="DM" variable="COUNTRY" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08">Value for COUNTRY '{data($country)}' is not found in ISO 3166</error> 
