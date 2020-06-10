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

(: Rule CG0033: when VISITNUM != null and is planned, then VISITNUM must be in TV.VISITNUM :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: Get the TV data :)
let $tvdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TV']
let $tvdatasetname := $tvdataset/def:leaf/@xlink:href
let $tvdatasetlocation := concat($base,$tvdatasetname)
(: and the OID of VISITNUM in TV dataset :)
let $tvvisitnumoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all other datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[not(@Name='TV')]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OID of the VISITNUM and VISIT variables, if any :)
    let $visitnumoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset that have a VISITNUM data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$visitnumoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of VISITNUM  and VISITDY :)
        let $visitnumvalue := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        (: and check whether there is such a value in TV, except when VISITNUM contains a "." (unplanned visit) :)
        let $isunplannedvisit := contains($visitnumvalue,'.') 
        (: count the number of records in TV for VISITNUM and VISIDY '1' :)
        let $recordsintv := doc($tvdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tvvisitnumoid][@Value=$visitnumvalue]]       
        let $recordsintvcount := count($recordsintv)
        (: no records found and not an unplanned visit :)
        where not($isunplannedvisit) and $recordsintvcount < 1
        return <error rule="CG0033" dataset="{data($name)}" variable="VISITNUM" rulelastupdate="2017-02-04" recordnumber="{data($recnum)}">Planned VISITNUM={data($visitnumvalue)} in dataset {data($datasetname)} is not found in the TV dataset</error>
		