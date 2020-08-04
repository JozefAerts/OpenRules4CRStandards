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

(: Rule CG0063: when there are multiple events per subject where DSCAT = 'DISPOSITION EVENT', 
 then EPOCH != null :)
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
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the dataset :)
let $dsdatasetlocation := (
	if($defineversion='2.1') then $dsitemgroupdef/def21:leaf/@xlink:href
	else $dsitemgroupdef/def:leaf/@xlink:href
)
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: get the OID of the EPOCH variable in DS :)
let $dsepochoid := (
    for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of USUBJID in DS :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: we also need the OID of DSCAT :)
let $dscatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSCAT']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: order the records in groups by the value of USUBJID, but only those that have DSCAT='DISPOSITION EVENT' :)
let $orderedrecords := (
    for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and @Value='DISPOSITION EVENT']]
        group by 
        $b := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
        return element group {  
            $record
        }
)
for $group in $orderedrecords
        (: each group has the same values for USUBJID:)
        let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
        (: get the number of records in this group :)
        let $recordcount := count($group/odm:ItemGroupData)
        (: iterate over the records in the group, but only when the group has multiple records :)
        for $record in $group[$recordcount>1]/odm:ItemGroupData 
            let $recnum := $record/@data:ItemGroupDataSeq
            (: each such a record must have an EPOCH variable :)
            where not($record/odm:ItemData[@ItemOID=$dsepochoid]/@Value)
            return <error rule="CG0063" variable="EPOCH" dataset="DS" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">EPOCH is missing for multiple DSCAT='DISPOSITION EVENT' occurrence for subject {data($usubjid)}</error>			
		
	