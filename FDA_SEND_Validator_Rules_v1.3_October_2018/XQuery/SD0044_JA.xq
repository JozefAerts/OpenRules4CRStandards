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
(: Rule SD0044 - Missing value for --VAMTU, when --VAMT is populated:
Treatment Vehicle Amount Units (--VAMTU) should not be NULL,  when Treatment Vehicle Amount (--VAMT) is populated
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
		else ()
	)
    (: get the OID of VAMTU and VAMT variables :)
    let $vamtuoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'VAMTU')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $vamtuname := $definedoc//odm:ItemDef[@OID=$vamtuoid]/@Name
    let $vamtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'VAMT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $vamtname := $definedoc//odm:ItemDef[@OID=$vamtoid]/@Name
    (: iterate over all records for which VAMT is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$vamtoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the VAMT variable :)
        let $vamtvalue := $record/odm:ItemData[@ItemOID=$vamtoid]/@Value
        (: and check whether VAMTU is populated :)
        let $vamtuvalue := $record/odm:ItemData[@ItemOID=$vamtuoid]/@Value
        where not($vamtuvalue)
        return <warning rule="SD0044" dataset="{data($name)}" variable="{data($vamtuname)}" rulelastupdate="2019-08-15" recordnumber="{data($recnum)}">Missing value for {data($vamtuname)}, when {data($vamtname)} is populated</warning>	
