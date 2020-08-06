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
	
(: TODO: Further testing - we did not have a good test sample :)
(: Rule SD0045 - Missing value for --STRESC, when --RESCAT is populated:
Character Result/Finding in Std Units (--STRESC) should be provided, when Result Category (--RESCAT) is specified
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
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over all FINDINGS domains :)
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
    (: and get the OIDs of the STRESC and RESCAT variables :)
    let $strescoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $strescname := $definedoc//odm:ItemDef[@OID=$strescoid]/@Name
    let $rescatoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'RESCAT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a     
    )
    let $rescatname := $definedoc//odm:ItemDef[@OID=$rescatoid]/@Name
    (: now iterate over all records in the dataset that DO have an RESCAT data point :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rescatoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values for STRESC and ORRES :)
        let $strescvalue := $record/odm:ItemData[@ItemOID=$strescoid]/@Value 
        let $rescatvalue := $record/odm:ItemData[@ItemOID=$rescatoid]/@Value
        (: we already selected on the presence of RESCAT,check whether STRESC is present :)
        where not($strescvalue) 
        return <warning rule="SD0045" dataset="{data($name)}" variable="{data($strescname)}" rulelastupdate="2019-03-09" recordnumber="{data($recnum)}">Missing {data($strescname)}, when {data($rescatname)} value={data($rescatvalue)} is provided in dataset {data($datasetname)}</warning>	
