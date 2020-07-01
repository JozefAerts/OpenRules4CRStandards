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

(: Rule SD0086 - IDVAR, IDVARVAL, and QNAM a unique combination per parent subject record :)
(: OPTIMIZED - made much more faster using "GROUP BY" :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all SUPP-- records :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')][@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: get the OID of USUBJID in the SUPP-- dataset :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the OID of IDVAR in the SUPP-- dataset :)
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the OID of IDVARVAL in the SUPP-- dataset :)
    let $idvarvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the OID of QNAM in the SUPP-- dataset :)
    let $qnamoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='QNAM']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
(: get the location of the SUPP-- dataset :)
let $suppdatasetlocation := $itemgroupdef/def:leaf/@xlink:href
let $suppdatasetdoc := doc(concat($base,$suppdatasetlocation))
(: group the records in the SUPP-- dataset by USUBJID,IDVAR,IDVARVAL,QNAM - there should be only one record per group :)
let $orderedrecords := (
        for $record in $suppdatasetdoc//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
            $c := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value,
            $d := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value,
            $e := $record/odm:ItemData[@ItemOID=$qnamoid]/@Value
            return element group {  
                $record
            }
        ) 
(: iterate over all the groups - in each group, all values of USUBJID,IDVAR,IDVARVAL,QNAM :)
for $group in $orderedrecords
    let $usubjidvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    let $idvar := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$idvaroid]/@Value
    let $idvarval := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
    let $qnam := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$qnamoid]/@Value
    let $recnum := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
    (: count the records in this group :)
    let $count := count($group/odm:ItemGroupData)
    where $count > 1
    return <error rule="SD0086" dataset="{data($name)}" rulelastupdate="2019-09-02" recordnumber="{data($recnum)}">The combination of USUBJID={data($usubjidvalue)}, IDVAR={data($idvar)}, IDVARVAL={data($idvarval)} and QNAM={data($qnam)} is not unique</error>			
		
	