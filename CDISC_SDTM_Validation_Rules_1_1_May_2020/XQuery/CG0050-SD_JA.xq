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

(: Rule CG0050: When --PTCD != null then --DECOD != null 
 Applicable to all EVENTS domain :)
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
let $datasetname := 'AE' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the single dataset :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
	let $dsname := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$dsname)
    (: get the OIDs of the --PTCD and --DECOD variables (if any) :)
    let $ptcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PTCD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $ptcdname := $definedoc//odm:ItemDef[@OID=$ptcdoid]/@Name
    let $decodoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DECOD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $decodname := $definedoc//odm:ItemDef[@OID=$decodoid]/@Name
    (: iterate over all the records in the dataset for which there is a --PTCD data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData/@ItemOID=$ptcdoid]
    let $recnum := $record/@data:ItemGroupDataSeq
        (: and check whether there is --DECOD data point :)
        let $ptcdvalue := $record/odm:ItemData[@ItemOID=$ptcdoid]/@Value
        let $decodvalue := $record/odm:ItemData[@ItemOID=$decodoid]/@Value
        where not($decodvalue)  (: there is no --DECOD value :)
        return <error rule="CG0050" dataset="{data($name)}" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Missing value for {data($decodname)}, when {data($ptcdname)} is populated (not null), value = {data($ptcdvalue)} in dataset {data($name)}</error>				
		
	