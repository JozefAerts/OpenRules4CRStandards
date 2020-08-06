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
	
(: Rule SD1123 - Value for --ORRES is populated, when --STAT is 'NOT DONE'
Value of Original Result (--ORRES) variable is expected to be missing, when observation was not performed (Status (--STAT) is 'NOT DONE')
:) 
(: ATTENTION: Message and Description do not match :)
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
(: iterate over all FINDINGS datasets :)
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
    (: get the OIDs of the --STAT, --DRVFL and --ORRES variable :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    let $orresoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORRES')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $orresname := $definedoc//odm:ItemDef[@OID=$orresoid]/@Name
    (: iterate over all records for which STAT has the value 'NOT DONE' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$statoid][@Value='NOT DONE']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ORRES  :)
        let $orresvalue := $record/odm:ItemData[@ItemOID=$orresoid]/@Value
        (: ORRES must be null :)
        where $orresvalue
        return <warning rule="SD1123" dataset="{data($name)}" variable="{data($orresname)}" rulelastupdate="2019-08-21" recordnumber="{data($recnum)}">{data($orresname)} value is populated (value={data($orresvalue)}), when {data($orresname)} is 'NOT DONE'  </warning>
