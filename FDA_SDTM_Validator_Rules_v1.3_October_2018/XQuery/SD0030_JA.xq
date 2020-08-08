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

(: Rule SD0030 - Missing value for --STRESC, when --STRESU is provided:
Character Result/Finding in Std Units (--STRESC) should not be NULL, when Standard Units (--STRESU) is provided
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
(: Iterate over all FINDINGS domains :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OIDs of the STRESU and STRESC variables :)
    let $strescoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $strescname := $definedoc//odm:ItemDef[@OID=$strescoid]/@Name
    let $stresuoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESU')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a     
    )
    let $stresuname := $definedoc//odm:ItemDef[@OID=$stresuoid]/@Name
    (: now iterate over all records in the dataset that DO have an STRESU :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$stresuoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values for STRESC and STRESU :)
        let $strescvalue := $record/odm:ItemData[@ItemOID=$strescoid]/@Value
        let $stresuvalue := $record/odm:ItemData[@ItemOID=$stresuoid]/@Value
        (: we already selected on the presence of STRESU, STRESC MUST be populated :)
         where not($strescvalue) 
        return <warning rule="SD0030" dataset="{data($name)}" variable="{data($strescname)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Missing value for {data($strescname)}, when {data($stresuname)} is provided, value={data($stresuvalue)} is provided in dataset {data($datasetname)}</warning>	
