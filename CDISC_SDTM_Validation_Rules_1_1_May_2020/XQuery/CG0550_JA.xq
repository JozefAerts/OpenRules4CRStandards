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

(: Rule CG0550: When --STREFC ^= null, then --STREFN ^= null :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
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
    (: get the OID of --STREFN :)
    let $strefnoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STREFN')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the full name :)
    let $strefnname :=  $definedoc//odm:ItemDef[@OID=$strefnoid]/@Name
    (: and the location of the dataset and document :)
	let $datasetname := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: iterate over all records in the dataset for which --STREFC is populated or --DRVFL='Y' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$strefcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STREFC (when any), and of STREFN (when any) :)
        let $strefc := $record/odm:ItemData[@ItemOID=$strefcoid]/@Value
        let $strefn := $record/odm:ItemData[@ItemOID=$strefnoid]/@Value
        (: give an error when --STREFC is populated but STREFN is not populated :)
        where $strefcoid and $strefc and  not($strefn)
        return <error rule="CG0550" dataset="{data($name)}" variable="{data($strefnname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">{data($strefnname)} is not populated although {data($strefcname)} is populated</error>							
	
	