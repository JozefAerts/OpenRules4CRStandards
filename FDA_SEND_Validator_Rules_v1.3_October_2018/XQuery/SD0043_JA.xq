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
	
(: TODO: needs further testing, did not have a good test dataset :)
(: Rule SD0043 - Missing value for --TRTV, when --VAMT is not NULL
Treatment Vehicle (--TRTV) should be provided, when Treatment Vehicle Amount (--VAMT) is specified
INTERVENTIONS
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
(: iterate over all INTERVENTION domains :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='INTERVENTIONS']
    let $name := $dataset/@Name
    let $domain := $dataset/@Domain
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else()
	)
    (: get the OID of TRTV and VAMT variables :)
    let $trtvoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TRTV')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $trtvname := $definedoc//odm:ItemDef[@OID=$trtvoid]/@Name
    let $vamtoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'VAMT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $vamtname := $definedoc//odm:ItemDef[@OID=$vamtoid]/@Name
    (: iterate over all records for which VAMT is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$vamtoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the VAMT variable :)
        let $vamtvalue := $record/odm:ItemData[@ItemOID=$vamtoid]/@Value
        (: and check whether TRTV is populated :)
        let $trtvvalue := $record/odm:ItemData[@ItemOID=$trtvoid]/@Value
        where not($trtvvalue)
        return <warning rule="SD0043" dataset="{data($name)}" variable="{data($trtvname)}" rulelastupdate="2020-07-01" recordnumber="{data($recnum)}">Missing value for {data($trtvname)}, when {data($vamtname)} is not NULL</warning>
