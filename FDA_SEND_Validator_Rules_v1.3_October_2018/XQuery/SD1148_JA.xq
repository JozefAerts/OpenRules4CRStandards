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
	
(: Rule SD1148: Start Date/Time of Treatment (EXSTDTC) variable value must be greater than or equal to Date/Time of Experimental Start Date (EXPSTDTC) in Trial Summary (TS) domain  :)
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
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetloc := (
	if($defineversion='2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
(: and the TS document itself :)
let $tsdoc := (
	if($tsdataset) then doc(concat($base,$tsdatasetloc))
    else()
)
(: get the OID of the TSPARMCD, ans TSVAL variable :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the value of the EXPSTDTC parameter :)
let $expstdtc := $tsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='EXPSTDTC']]/odm:ItemData[@ItemOID=$tsvaloid]/@Value
(: Iterate over the EX datasets - there should be only one :)
for $exdataset in $definedoc//odm:ItemGroupDef[starts-with(@Name,'EX')]
	let $name := $exdataset/@Name
    (: get the location and the document itself :)
	let $exdatasetloc := (
		if($defineversion='2.1') then $exdataset/def21:leaf/@xlink:href
		else $exdataset/def:leaf/@xlink:href
	)
    let $exdoc := doc(concat($base,$exdatasetloc))
    (: get the OID of the EXSTDTC variable :)
	let $exstdtcoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='EXSTDTC']/@OID 
    	where $a = $exdataset/odm:ItemRef/@ItemOID
    	return $a
    )
	(: Iterate over all records and get the value of EXSTDTC :)
    for $record in $exdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$exstdtcoid]]
    	let $recnum := $record/@data:ItemGroupDataSeq
        let $exstdtc := $record/odm:ItemData[@ItemOID=$exstdtcoid]/@Value
        (: Value of EXSTDTC must be on or after EXPSTDTC :)
		(:  TODO 2020-08-05: case that one or both values are of type xs:date :)
        where $exstdtc and xs:dateTime($exstdtc) < xs:dateTime($expstdtc) 
		return <error rule="SD1148" dataset="{data($name)}" variable="EXSTDTC" recordnumber="{data($recnum)}" rulelastupdate="2020-06-25">Value of EXSTDTC={data($exstdtc)} is before TS.EXPSTDTC={data($expstdtc)}</error>  

