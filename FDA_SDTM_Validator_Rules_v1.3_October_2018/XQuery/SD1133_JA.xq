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

(: Rule SD1133: Inconsistent value for ACTARM
A value for Description of Actual Arm (ACTARM) must have a unique value for Actual Arm Code (ACTARMCD) with the domain. :)
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
(: Iterate over the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
    let $name := $dataset/@Name
    let $datasetname := ( 
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OID of ACTARMCD and ACTARM :)
    let $actarmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $actarmoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: group by ACTARMCD - each group has the same value of ACTARMCD :)
    let $orderedrecords := (
        for $record in doc($datasetlocation)//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
            return element group {  
                $record
            }
    )
    (: iterate over the groups, get the first record only to indentify ACTARMCD and ACTARM :)
    for $group in $orderedrecords
        let $actarmcdvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
        let $actarmvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$actarmoid]/@Value
        let $recnum := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        (: now check whether there are any other records that have a different value for ACTARM :)
        for $record in $group/odm:ItemGroupData[position()>1]
            let $actarmvalue2 := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
            (: if the ACTARM value is different from that within the first record of the group, give an error :)
            let $recnum2 := $record/@data:ItemGroupDataSeq
            where $actarmvalue != $actarmvalue2
            return <error rule="SD1133" dataset="{data($name)}" variable="ACTARM" recordnumber="{data($recnum2)}" rulelastupdate="2020-08-08">Non-unique value for ACTARM within ACTARMCD '{data($actarmcdvalue)}' in dataset {data($datasetname)}. Record {data($recnum2)} has ACTARM value '{data($actarmvalue2)}' whereas record {data($recnum)} has ACTARM value '{data($actarmvalue)}'</error>

