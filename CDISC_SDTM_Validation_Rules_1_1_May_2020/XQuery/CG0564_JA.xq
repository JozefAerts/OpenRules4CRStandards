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

(: Rule CG0564: --AGENT not present in Findings dataset, except for MS :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all Findings datasets, except for MS :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' and not(@Name='MS') and not(@domain='MS')]
	let $name := $itemgroupdef/@Name
    let $domain := (
    	if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2)
    )
    (: get the --AGENT variable (when present) :)
    let $agentoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'AGENT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $agentname := $definedoc//odm:ItemDef[@OID=$agentoid]/@Name
    (: --AGENT is not allowed to be present, so give an error when it is present :)
    where $agentoid
    return <error rule="CG0564" dataset="{data($name)}" rulelastupdate="2020-06-22">Variable {data($agentname)} is not allowed to be used in SDTM submissions</error>			
	
	