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
	
(: TODO - not well tested yet :)
(: Rule SD0024 - Missing value for --DTC, when --ENDTC is provided:
Date/Time of Collection (--DTC) should not be NULL, when End Date/Time of Observation (--ENDTC) is not NULL
Findings domains
:)
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
(: iterate over all the FINDINGS datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: get the OID of the ENDTC variable :)
    let $endtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $endtcname := $definedoc//odm:ItemDef[@OID=$endtcoid]/@Name
    (: and the OID of the DTC variable (5 characters) :)
    let $dtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DTC') and string-length(@Name)=5]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dtcname := $definedoc//odm:ItemDef[@OID=$dtcoid]/@Name
    (: now iterate over all records in the dataset that have an ENDTC that is not null :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData/@ItemOID=$endtcoid]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of the ENDTC and DTC variables (if any) :)
        let $endtcvalue := $record/odm:ItemData[@ItemOID=$endtcoid]/@Value
        let $dtcvalue := $record/odm:ItemData[@ItemOID=$dtcoid]/@Value
        (: check whether there is a DTC value when an ENDTC value is present  :)
        (: where $endtcvalue and not($dtcvalue) :)
        return <warning rule="SD0024" rulelastupdate="2019-08-17" recordnumber="{data($recnum)}">Missing value for {data($dtcname)}, when {data($endtcname)} is provided, value={data($endtcvalue)}</warning>
