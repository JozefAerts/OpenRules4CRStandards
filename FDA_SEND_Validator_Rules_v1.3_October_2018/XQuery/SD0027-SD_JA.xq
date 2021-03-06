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
	
(: Rule SD0027 - Missing value for --ORRES, when --ORRESU is provided:
Result or Finding in Original Units (--ORRES) should not be NULL, when Original Units (--ORRESU) is provided
All FINDINGS datasets
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over all provided datasets in the FINDINGS domains :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($dsname) then doc(concat($base,$dsname))
		else ()
	)
    (: and get the OIDs of the ORRES and ORRESU variables :)
    let $orresoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORRES')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $orresname := $definedoc//odm:ItemDef[@OID=$orresoid]/@Name
    let $orresuoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORRESU')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a     
    )
    let $orresuname := $definedoc//odm:ItemDef[@OID=$orresuoid]/@Name
    (: now iterate over all records in the dataset that have an ORRESU :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$orresuoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values for ORRESU and ORRES :)
        let $orresvalue := $record/odm:ItemData[@ItemOID=$orresoid]/@Value
        let $orresuvalue := $record/odm:ItemData[@ItemOID=$orresuoid]/@Value
        (: we already selected on the presence of ORRESU, check whether there is an ORRES :)
         where not($orresvalue) 
        return <warning rule="SD0027" variable="{data($orresname)}" dataset="{data($name)}" rulelastupdate="2019-08-30" recordnumber="{data($recnum)}">Missing value for {data($orresname)}, when {data($orresuname)}, value={data($orresuvalue)} is provided in dataset {data($datasetname)}</warning>
