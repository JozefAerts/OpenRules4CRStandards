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

(: Rule SD1320 - Missing value for --STRESC, when --STAT is null - FINDINGS domains
Character Result/Finding in Std Format (--STRESC) value should not be NULL, when Status Flag (--STAT) value is null.
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
(: let $base := '/db/fda_submissions/cdisc01/'
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the FINDINGS datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
    let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Find the OID of the --STAT variable  :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the name :)
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    (: Find the OID and the name of the --STRESC variable :)
    let $strescoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strescname := $definedoc//odm:ItemDef[@OID=$strescoid]/@Name
    (: iterate over all the records, but only if there really is a --STAT variable (as it is permissible) :)
    (: TODO: to speed things up, an "IF" is needed here :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the value of the DRVFL variable :)
        let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        (: and of the STRESC variable (if any) :)
        let $strescvalue := $record/odm:ItemData[@ItemOID=$strescoid]/@Value
        (: when --STAT exists and --STAT=null ensure there is a STRESC data point :)
        where $statoid and (not($statvalue) and not($strescvalue))
        return <warning rule="SD1320" rulelastupdate="2020-08-08" dataset="{data($name)}" variable="{data($strescname)}" recordnumber="{data($recnum)}">Missing value for {data($strescname)}, when {data($statname)}=null</warning>
	
