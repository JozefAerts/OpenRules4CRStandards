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

(: Rule SD1052 - Non-unique value for TAETORD within ARMCD:
Order of Element within Arm (TAETORD) must have a unique value for a given value of Planned Arm Code (ARMCD) within the domain
:)
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
(: Get the TA dataset :)
let $tadatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/def:leaf/@xlink:href
let $tadatasetdoc := (
	if($tadatasetname) then doc(concat($base,$tadatasetname))
	else ()
)
(: also need to find out the OIDs of ARMCD and TAETORD :)
let $taarmcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
        return $a
)
let $tataetordoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TAETORD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records in the TA dataset :)
for $record in $tadatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: Get the value of ARMCD and TAETORD :)
    let $taarmcdvalue := $record/odm:ItemData[@ItemOID=$taarmcdoid]/@Value
    let $tataetordvalue := $record/odm:ItemData[@ItemOID=$tataetordoid]/@Value
    (: and have a second iteration over all subsequent record :)
    for $nextrecord in $tadatasetdoc//odm:ItemGroupData[@data:ItemGroupDataSeq > $recnum]
        let $recnumnext := $nextrecord/@data:ItemGroupDataSeq
        (: and look for duplicate values :)
        let $taarmcdvaluenext := $nextrecord/odm:ItemData[@ItemOID=$taarmcdoid]/@Value
        let $tataetordvaluenext := $nextrecord/odm:ItemData[@ItemOID=$tataetordoid]/@Value
        where $taarmcdvalue = $taarmcdvaluenext and $tataetordvalue = $tataetordvaluenext
    return <error rule="SD1052" dataset="TA" variable="TAETORD" rulelastupdate="2019-08-29" recordnumber="{data($recnumnext)}">Non-unique value for TAETORD within ARMCD. Records {data($recnum)} and {data($recnumnext)} have the same value for ARMCD={data($taarmcdvalue)} and TAETORD={data($tataetordvalue)} in TA dataset {data($tadatasetname)}</error>
