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

(: Rule CG0410 - VISITNUM identifies unique record within subject, for scheduled or contingent visit :)
(: OPTIMIZED - made much more faster using "GROUP BY" :)
(: New in this version: only applies for VISITNUM that occur in TV :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
let $svitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SV']
(: get the OID of VISITNUM in define.xml for dataset SV :)
let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )  
(: get the OID of USUBJID in the SV dataset :)
let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $svitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
(: get the location of the SV dataset :)
let $svdatasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='SV']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='SV']/def:leaf/@xlink:href
)
let $svdatasetdoc := (
	if($svdatasetname) then doc(concat($base,$svdatasetname))
	else ($svdatasetname)
)
(: group the records in the SV dataset by USUBJID and VISITNUM - there should be only one record per group :)
let $orderedrecords := (
        for $record in $svdatasetdoc//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
            $c := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
            return element group {  
                $record
            }
        )
(: iterate over all the groups :)
for $group in $orderedrecords
    let $visitnumvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$visitnumoid]/@Value
    let $usubjidvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    let $recnum := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
    let $count := count($group/odm:ItemGroupData)
    where $count > 1
    return <error rule="CG0410" dataset="SV" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">SV.VISITNUM does not uniquely identify records within subject - combination of USUBJID={data($usubjidvalue)} and VISITNUM={data($visitnumvalue)} occurrs {data($count)} times</error>				
		
	