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

(: Rule SD1280: For LB and AE: --TOX variable may not be present when --TOXGR variable is missing :)
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
(: Iterate over the LB and AE datasets - keep 'splitted' datasets into account :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'LB') or starts-with(@Name,'AE')]
    let $name := $itemgroupdef/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OID and name of --TOXGR and of ----TOX :)
    let $toxgroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TOXGR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $toxgrname := $definedoc//odm:ItemDef[@OID=$toxgroid]/@Name
    let $toxoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TOX')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $toxname := $definedoc//odm:ItemDef[@OID=$toxoid]/@Name
    (: When --TOXGR is absent than --TOX must be absent :)
    where $datasetdoc and not($toxgroid) and $toxoid (: error when --TOXGR is absent and --TOX is present :)
    return 
    <error rule="SD1280" rulelastupdate="2020-08-08" dataset="{data($name)}" variable="{data($toxname)}">{data($toxname)} is present, although {data($toxgrname)} is absent in dataset {data($name)}</error>	
		
	