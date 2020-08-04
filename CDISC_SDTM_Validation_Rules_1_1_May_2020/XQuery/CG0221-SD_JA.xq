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

(: Rule CG0221 - When --STDTC or DM.RFSTDTC does not contain complete values in their date portion then --STDY = null :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))

(: get the location of the DM dataset :)
let $dmdatasetname := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdatasetlocation := concat($base,$dmdatasetname)
let $dmdatasetdoc := doc($dmdatasetlocation)
(: and the OIDs of the USUBJID and RFSTDTC variables :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
)
(: iterate over all selected datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[not(@Name='DM')][@Name=$datasetname]
    let $name := $datasetdef/@Name
	let $dsname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$dsname)
    let $datasetdoc := doc($datasetlocation)
    (: Get the OIDs of the SDTY and STDTC variable :)
    let $stdyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDY')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a  
    )
    let $stdyname := $definedoc//odm:ItemDef[@OID=$stdyoid]/@Name
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a  
    )
    let $stdtcname := $definedoc//odm:ItemDef[@OID=$stdtcoid]/@Name
    (: and the OID of USUBJID in this dataset (can be different from in DM) :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset that DO have both a STDCT value  :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $stdtcvalue := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
        (: check whether it is a complete date :)
        let $iscompletestdtcdate := string-length($stdtcvalue) >= 10  (: boolean :)
        (: get the USUBJID and get the corresponding RFSTDTC in the DM dataset :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: taking the worst case scenario into account that there is more than one record for a USUBJID in DM - take the first one :)
        let $rfstdtcvalue := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: and check whether RFSTDTC is a complete date :)
        let $iscompleterfstdtcdate := string-length($rfstdtcvalue) >= 10
        (: Get the value of the STDY variable (if any) :)
        let $stdyvalue := $record/odm:ItemData[@ItemOID=$stdyoid]/@Value
        (: STDY may NOT be populated when of RFSTDTC or STDTC is an incomplete date :)
        where $stdyoid and (not($iscompletestdtcdate) or not($iscompleterfstdtcdate)) and $stdyvalue
        return <error rule="CG0221" dataset="{data($name)}" variable="{data($stdyname)}" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">{data($stdyname)} variable value {data($stdyvalue)} is not null although one of {data($stdtcname)} (value={data($stdtcvalue)}) or RFSTDTC (value={data($rfstdtcvalue)}) is not a  complete date</error>				
		
	