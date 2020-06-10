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

(: Rule CG0053 when --PRESP not present in dataset then --REASND not present in dataset
 Applies to: EVENTS,INTERVENTIONS, NOT(DS, DV, EX) :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Applies to: EVENTS,INTERVENTIONS, NOT(DS, DV, EX) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS'][not(@Domain='DS') and not(@Domain='DV') and not(@Domain='EX')]
    let $name := $itemgroupdef/@Name
    (: find the OID and name of the --PRESP variable /(if any) :)
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[OID=$prespoid]/@Name
    (: and of the --REASND variable :)
    let $reasndoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'REASND')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $reasndname := $definedoc//odm:ItemDef[@OID=$reasndoid]/@Name
    (: when --PRESP is absent, --REASND must be absent :)
    where not($prespoid) and $reasndoid
    return <error rule="CG0053" variable="{data($reasndname)}" dataset="{$name}" rulelastupdate="2019-08-21">{data($reasndname)} is present although {data($prespname)} is absent</error>			
		