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

(: Rule SE2317: The value of Parameter Code (TXPARMCD) variable must be unique for each Trial Set (SETCD) within the Trial Sets (TX) domain :)
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
(: let $base := 'SEND_3_0_PC201708/' :)
(: let $define := 'define.xml' :)
(: the define.xml document itself :)
let $definedoc := doc(concat($base,$define))
(: we need the OID of SETCD and TXPARMCD in TX :)
let $setcdoid := (
	for $a in $definedoc//odm:ItemDef[@Name='SETCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='TX']/odm:ItemRef/@ItemOID
        return $a
)
let $txparmcdoid := (
	for $a in $definedoc//odm:ItemDef[@Name='TXPARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='TX']/odm:ItemRef/@ItemOID
        return $a
)
(: Get the TX document :)
let $txloc := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='TX']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='TX']/def:leaf/@xlink:href
)
let $txdoc := (
	if($txloc) then doc(concat($base,$txloc))
    else () (: TX is not present :)
)
(: Group all records in TX by the value of SETCD and TXPARMCD - 
there may be only 1 record in each group :)
let $groupedrecords := (
	for $record in $txdoc//odm:ItemGroupData
            group by 
            $a := $record/odm:ItemData[@ItemOID=$setcdoid]/@Value,
            $b := $record/odm:ItemData[@ItemOID=$txparmcdoid]/@Value
            return element group {  
                $record
            }
)
(: In each group, all the records have the same value for SETCD and TXPARMCD. 
Count the number of records in each group, 
keep the record numbers for reporting :)
for $group in $groupedrecords
	let $txparmcdvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$txparmcdoid]/@Value
	let $setcdvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$setcdoid]/@Value
    let $count := count($group/odm:ItemGroupData)
    let $recnums := $group/odm:ItemGroupData/@data:ItemGroupDataSeq
    (: there may be only 1 record per group :)
    where $count > 1
    return <error rule="SE2317" dataset="TX" variable="TXPARMCD" recordnumber="{data($recnums[last()])}" rulelastupdate="2020-06-26">Duplicate value '{data($txparmcdvalue)}' for records {data($recnums)} for SETCD='{data($setcdvalue)}' in TX</error>

