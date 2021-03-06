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

(: Rule SD0072 - Invalid RDOMAIN:
Related Domain Abbreviation (RDOMAIN) must have a valid value of Domains included in the study data (CO,RELREC,SUPxx)
:)
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
(: Get the RELREC, CO and SUPPxx datasets :)
let $datasets := $definedoc//odm:ItemGroupDef[@Name='RELREC' or @Name='CO' or starts-with(@Name,'SUPP')]
(: iterate over these datasets :)
for $dataset in $datasets
    let $name := $dataset/@Name
    (: Get the dataset location :)
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OID of the RDOMAIN variable :)
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: now iterate over all the record in these dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the RDOMAIN variable :)
        let $rdomainvalue := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        (: and check whether defined in the define.xml - we take into account that sometimes the "Domain" attribute is missing :)
        where not($definedoc//odm:ItemGroupDef[@Domain=$rdomainvalue or @Name=$rdomainvalue])
        return <error rule="SD0072" dataset="{data($name)}" variable="RDOMAIN" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid value for RDOMAIN='{data($rdomainvalue)}' in dataset {data($datasetname)} - domain {data($rdomainvalue)} was not found in the define.xml file {data($define)}</error>
