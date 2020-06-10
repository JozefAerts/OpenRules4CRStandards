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

(: Rule CG0050/FDA-SD1288 - Inconsistent value for --PTCD within --DECOD - 
 All values of Preferred Term Code (--PTCD) should be the same for a given value of Dictionary-Derived Term (--DECOD) :)
(: Made faster using "GROUP BY" :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the EVENTS datasets :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef[@def:Class='EVENTS']
    let $name := $itemgroupdef/@Name
    let $datasetname := $itemgroupdef/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OID of --DECOD and --PTCD :)
    let $decodoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DECOD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a 
    )
    let $decodname := $definedoc//odm:ItemDef[@OID=$decodoid]/@Name (: and the name (for reporting) :)
    let $ptcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PTCD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a 
    )
    let $ptcdname := $definedoc//odm:ItemDef[@OID=$ptcdoid]/@Name (: and the name (for reporting) :)
    (: group all the records in the dataset (at least when -PTCD and -DECOD are present by -DECOD. :)
    (: all the records in the same group then have the same values for -DECOD :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$decodoid]/@Value
            return element group {  
                $record
            }

    )
    (: we only need to iterate over the groups, and only take the first record in the group,
    as within the group, all the records have the same values for -DECOD :)
    for $group in $orderedrecords[$ptcdoid and $decodoid]
        let $decod := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$decodoid]/@Value
        let $ptcd1 := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$ptcdoid]/@Value
        let $recnum1 := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        for $record in $group/odm:ItemGroupData[position()>1]  (: start from the second one  :)
            let $recnum2 := $record/@data:ItemGroupDataSeq
            (: as we grouped, the value of PTCD is the same, but we need to check on -DECOD :)
            let $ptcd2 := $record/odm:ItemData[@ItemOID=$ptcdoid]/@Value
            (: the two -PTCD values must be identical, as they have the same value for -DECOD :)
            where not($ptcd1 = $ptcd2)
            return <error rule="SD1288" dataset="{$name}" variable="{data($decodname)}" rulelastupdate="2019-08-20" recordnumber="{$recnum2}">Inconsistent value for {data($ptcdname)} within {data($decodname)}: Record {data($recnum2)} has {data($ptcdname)}={data($ptcd2)} whereas recordnumber={data($recnum1)} has {data($ptcdname)}={data($ptcd1)} for the same value of {data($decodname)}={data($decod)}</error>  

	