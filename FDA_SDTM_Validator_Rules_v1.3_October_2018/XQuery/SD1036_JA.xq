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
	
(: Rule SD1036 - Missing value for --TOXGR, when --TOX is populated:
Toxicity Grade (--TOXGR) should be provided, when Toxicity (--TOX) is populated
Domains: AE, MH, CE, EG, LB, PC, PP
:)
(: TODO: better testing, we did not have a good test dataset :)
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
(:  iterate over the AE, MH, CE, EG, LB, PC, PP datasets :)
for $dataset in $definedoc/odm:ItemGroupDef[starts-with(@Name,'AE') or @Domain='AE' or starts-with(@Name,'MH') or @Domain='MH' or starts-with(@Name,'CE') or @Domain='CE' or starts-with(@Name,'EG') or @Domain='EG' or starts-with(@Name,'LB') or @Domain='LB' or starts-with(@Name,'PC') or @Domain='PC' or starts-with(@Name,'PP') or @Domain='PP']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the TOX and TOXGR variables :)
    let $toxoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TOX')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $toxname := $definedoc//odm:ItemDef[@OID=$toxoid]/@Name
    let $toxgroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TOXGR')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $toxgrname := $definedoc//odm:ItemDef[@OID=$toxgroid]/@Name
    (: get all records for which TOX is populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$toxoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and the value of TOX :)
        let $toxvalue := $record/odm:ItemData[@ItemOID=$toxoid]/@Value
        (: and check whether TOXGR is populated :)
        let $toxgrvalue := $record/odm:ItemData[@ItemOID=$toxgroid]/@Value
        where not($toxgrvalue)
        return <warning rule="SD1036" dataset="{data($name)}" variable="{data($toxgrname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum}">Missing value for {data($toxgrname)}, when {data($toxname)} is populated, value={data($toxvalue)}</warning>
