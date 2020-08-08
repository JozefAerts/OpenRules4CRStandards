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

(: Rule SD0002: NULL value in variable marked as Required - Required variables (where Core attribute is 'Req') cannot be NULL for any records :)
(: Until 2020-08-08, the implementation relies on that the define.xml is complete and 
 that Mandatory='Yes' is set for each required variable :)
(: As of 2020-08-08 it uses a RESTful web service to find out what the "core" status of the variable is
 TODO: use CDISC Library API for this :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'LB' :)
let $definedoc := doc(concat($base,$define))
(: The base of the RESTful web service :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CDISCCoreFromSDTMVariable/'
(: The SDTM-IG version this define.xml refers to :)
(: TODO: for v.2.1 get standard version at the dataset definition level :)
let $igversion := (
	if($defineversion = '2.1') then $definedoc //odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG'][1]/@Version
	else $definedoc //odm:MetaDataVersion/@def:StandardVersion
)
(:  get the definitions for the provided datasets (ItemGroupDefs in define.xml) :)
for $itemgroup in $definedoc //odm:ItemGroupDef[@Name=$datasetname]
    let $itemgroupoid := $itemgroup/@OID
    let $dataset := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dsname := $itemgroup/@Name
    let $datasetpath := concat($base,$dataset)
    let $domain := $itemgroup/@Domain  (: The domain this dataset belongs to :)
    
    (: iterate over all ItemRefs that are mandatory, corresponding to 'required' variables :)
    for $itemref in $itemgroup/odm:ItemRef
        let $itemrefoid := $itemref/@ItemOID
        let $itemname := $definedoc //odm:ItemDef[@OID=$itemrefoid]/@Name
        (: get the "core" status from the RESTful web service :)
        let $query := concat($webservicebase,$igversion,'/',$domain,'/',$itemname)
        (: return <test>{data($query)}</test> :)
        (: Execute the RESTful web service query and get the value for "core" :)
        let $core := doc($query)//Response/text() 
        (: iterate over each dataset record :)
        for $record in doc($datasetpath)//odm:ItemGroupData[@ItemGroupOID=$itemgroupoid] 
            (: get the record number :)
            let $recnum := $record/@data:ItemGroupDataSeq 
            (: data point is absent in this record, althout "core" is "Req" :)
            where $core='Req' and empty($record/odm:ItemData[@ItemOID=$itemrefoid])
            return <error rule="SD0002" dataset="{$datasetname}" variable="{data($itemname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum}">No data found for required variable {data($itemname)} in record number {data($recnum)} in dataset {data($datasetname)}</error> 

