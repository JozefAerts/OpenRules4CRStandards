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

(: Rule CG0035 - VISIT and VISITNUM have a one-to-one relationship
Precondition: VISITNUM in TV.VISITNUM
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external; 
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml'
let $datasetname := 'LB' :)
let $definedoc := doc(concat($base,$define))
(: Precondition is that VISITNUM is in TV, so we need the OID of VISITNUM in TV :)
let $visitnumtvoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
    return $a 
)
(: and the location of the TV document :)
let $tvlocation := $definedoc//odm:ItemGroupDef[@Name='TV']/def:leaf/@xlink:href
let $tvdatasetdoc := doc(concat($base,$tvlocation))
(: Iterate over the datasets :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    let $dsname := $itemgroupdef/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OID of VISITNUM and VISIT :)
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a 
    )
    let $visitoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISIT']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a 
    )
    let $orderedrecords := 
    ( for $record in $datasetdoc[$visitnumoid and $visitoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$visitnumoid] and odm:ItemData[@ItemOID=$visitoid]]
        group by 
        $b := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value,
        $c := $record/odm:ItemData[@ItemOID=$visitoid]/@Value
        return element group {  
            $record
        }
    )
    (: for $group1 in $orderedrecords :)
    for $index1 in (1 to fn:count($orderedrecords))
        let $group1 := $orderedrecords[$index1]
    (: each group has the same value for VISITNUM and VISIT  :)
        let $visitnum1 := $group1/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        let $visit1 := $group1/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitoid]/@Value
        let $recnum1 := $group1/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        for $index2 in (($index1+1) to fn:count($orderedrecords))
            let $group2 := $orderedrecords[$index2]
            let $visitnum2 := $group2/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitnumoid]/@Value
            let $visit2 := $group2/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitoid]/@Value
            (: we want to have the sequence numbers for reporting :)
            let $recnum2 := $group2/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
            (: return <test>{data($visitnum1)} - {data($visit1)} - {data($visitnum2)} - {data($visit2)}</test> :)
            where $visitnum1 = $visitnum2 and $visit1 != $visit2
            return <error rule="CG0035" rulelastupdate="2020-06-11" dataset="{data($name)}" variable="VISITNUM" recordnumber="{data($recnum2)}">Combination of VISIT='{data($visit2)}' and VISITNUM={data($visitnum2)} in dataset {data($name)} is inconsistent: 
                record {data($recnum1)}: VISITNUM={data($visitnum1)} - VISIT='{data($visit1)}', 
                record {data($recnum2)}: VISITNUM={data($visitnum2)} - VISIT='{data($visit2)}'</error>		
		
	