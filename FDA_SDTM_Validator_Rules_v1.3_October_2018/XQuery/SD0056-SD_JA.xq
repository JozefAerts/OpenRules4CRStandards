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

(: Rule SD0056-FDAC018: SDTM Required variable not found - Variables described in SDTM as Required must be included in the dataset :)
(: The following Query relies on that the define.xml is complete and 
 that Mandatory='Yes' is set for each required variable :)
(: TODO: base "required" on information from the CDISC Library API through a RESTful web service :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets mentioned in the define.xml and passed by the calling program through external variable $domain :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    (: get all the ItemRef-OIDs which have 'Mandatory="Yes" :)
    let $mandatory := $itemgroup/odm:ItemRef[@Mandatory='Yes']/@ItemOID
    (: get the dataset itself :)
	let $datasetfilename := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := doc(concat($base,$datasetfilename))
    let $name := $itemgroup/@Name
    (: iterate over all the records :)
    for $record in $dataset//odm:ItemGroupData
    	let $recnum := $record/@data:ItemGroupDataSeq
    	(: iterate over the 'mandatory' OIDs  :)
    	for $m in $mandatory
        	(: and give an error when there is no such ItemData/@ItemOID  :)
        	let $varname := $definedoc//odm:ItemDef[@OID=$m]/@Name
        	where not($record/odm:ItemData[@ItemOID=$m])
        	return <error rule="SD0056" datasetname="{$name}" variable="{data($varname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum}">No data found for required variable {data($varname)} in record number {data($recnum)} in dataset {data($datasetname)}</error>
