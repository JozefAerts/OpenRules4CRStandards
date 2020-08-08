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
	
(: Rule SD1037 - Missing value for --TOX, when --TOXGR is populated:
A value for a Toxicity (--TOX) variable should be provided, when a Toxicity Grade (--TOXGR) variable value is populated and greater than 0
:)
(: TODO: better testing, we did not have a good dataset for this :)
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
    (: get all records for which TOXGR is populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$toxgroid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and the value of TOX :)
        let $toxgrvalue := $record/odm:ItemData[@ItemOID=$toxgroid]/@Value
        (: and check whether TOX is populated, when TOXGR>0 :)
        let $toxvalue := $record/odm:ItemData[@ItemOID=$toxoid]/@Value
        where number($toxgrvalue) and not($toxvalue)
        return <warning rule="SD1037" dataset="{data($name)}" variable="{data($toxname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum}">Missing value for {data($toxname)}, when {data($toxgrname)} is populated with a value >0, value={data($toxgrvalue)}</warning>	
