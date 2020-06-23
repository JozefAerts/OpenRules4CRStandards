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

(: Rule CG0549: When --ORREF ^= null or --DRVFL='Y', then --STREFC ^= null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $itemgroupdef/@Name
    let $domainname := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($itemgroupdef/@Name,1,2)
    )
    (: get the OID of --STREFC :)
    let $strefcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STREFC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the full name :)
    let $strefcname := $definedoc//odm:ItemDef[@OID=$strefcoid]/@Name
    (: get the OIDs of --ORREF and of --DRVFL :)
    let $orrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORREF')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $orrefname :=  $definedoc//odm:ItemDef[@OID=$orrefoid]/@Name
    let $drvfloid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DRVFL')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $drvflname := concat($domainname,'DRVFL')  (: for the case that --DRVFL is not defined in the dataset :)
    (: Get the OID of --STREFC :)
    let $strefcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STREFC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the location of the dataset and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset for which --ORREF is populated or --DRVFL='Y' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$orrefoid] or odm:ItemData[@ItemOID=$drvfloid]/@Value='Y']
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STREFC (when any) :)
        let $strefc := $record/odm:ItemData[@ItemOID=$strefcoid]/@Value
        (: give an error when --STREFC is present as a variable but is not populated :)
        where $strefcoid and not($strefc)
        return <error rule="CG0549" dataset="{data($name)}" variable="{data($strefcname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-22">{data($strefcname)} is not populated although {data($orrefname)} is populated or {data($drvflname)}='Y'</error>						
	
	