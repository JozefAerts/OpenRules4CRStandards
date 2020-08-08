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

(: Rule SD0004 - Inconsistent value for DOMAIN:
Domain Abbreviation (DOMAIN) variable should be consistent with the name of the dataset :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all provided datasets in the define.xml :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
	let $itemgroupdefname := $itemgroup/@Name
    (: get the dataset name and location :)
	let $dsname := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$dsname)
    (: get the OID of the "DOMAIN" variable :)
    let $domainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
    (: where $a = $definedoc//odm:ItemGroupDef/odm:ItemRef/@ItemOID :)
    where $a = $itemgroup/odm:ItemRef/@ItemOID
    return $a 
    )
    (: now get the unique values in the dataset - the number of unique values must be 1 :)
    let $distinctdomainvalues := distinct-values(doc($dataset)//odm:ItemData[@ItemOID=$domainoid]/@Value)
    where count($distinctdomainvalues) > 1
    return <error rule="SD0004" dataset="{data($itemgroupdefname)}" variable="DOMAIN" rulelastupdate="2020-08-08">Inconsistent Domain Abbreviation (DOMAIN) variable value in dataset {data($datasetname)}. Following values were found: {data($distinctdomainvalues)}</error>		
