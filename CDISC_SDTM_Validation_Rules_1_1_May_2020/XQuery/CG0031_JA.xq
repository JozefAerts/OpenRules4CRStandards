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

(: Rule CG0031: VISIT in TV.VISIT
For planned visits, values of VISIT must be defined in the Trial Visits dataset
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TV data :)
let $tvdataset := $definedoc//odm:ItemGroupDef[@Name='TV']
let $tvdatasetname := (
	if($defineversion='2.1') then $tvdataset/def21:leaf/@xlink:href
	else $tvdataset/def:leaf/@xlink:href
)
let $tvdatasetlocation := concat($base,$tvdatasetname)
(: and the OID of the VISIT and VISITNUM in TV dataset :)
let $tvvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a
)
let $tvvisitoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all other datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[not(@Name='TV')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
	let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: Get the OID of the VISITNUM and VISIT variables, if any :)
    let $visitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
    return $a
    )
    let $visitoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset that have a VISIT and VISITNUM data point :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$visitnumoid] and odm:ItemData[@ItemOID=$visitoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of VISIT and VISITNUM :)
        let $visitnumvalue := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        let $visitvalue := $record/odm:ItemData[@ItemOID=$visitoid]/@Value
        (: and check whether there is such a value in TV, except when VISITNUM contains a "." (unplanned visit) :)
        let $isunplannedvisit := contains($visitnumvalue,'.') 
        (: count the number of records in TV for this combination of VISIT and VISITNUM - the count should give '1' :)
        let $recordsintv := doc($tvdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tvvisitnumoid][@Value=$visitnumvalue] and odm:ItemData[@ItemOID=$tvvisitoid][@Value=$visitvalue]]       
        let $recordsintvcount := count($recordsintv)
        (: no records found and not an unplanned visit :)
        where not($isunplannedvisit) and $recordsintvcount < 1
        return <error rule="CG0031" dataset="{data($name)}" variable="VISITNUM" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">VISIT={data($visitvalue)}, VISITNUM={data($visitnumvalue)} in dataset {data($datasetname)} is not defined in the TV dataset</error>			
		
	