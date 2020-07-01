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

(: Rule SD1103 Missing --STTPT variable, when --STRTPT variable is present - Start Reference Time Point (--STTPT) variable must be included into the domain, when Start Relative to Reference Time Point (--STRTPT) variable is present :)
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
(: Iterate over all datasets defined in the define.xml within INTERVENTIONS, EVENTS, FINDINGS, SE :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Domain='SE']
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else $name
    )
    (: find the OID and name of the --STTPT variable /(if any) :)
    let $sttptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $sttptname := $definedoc//odm:ItemDef[@OID=$sttptoid]/@Name
    (: and of the --STRTPT variable :)
    let $strtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $strtptname := concat($domain,'STRTPT')  (: as when --TRTPT is absent, we also do now its name :)
    (: when --STTPT present in dataset then --STRTPT must present in dataset :)
    where $strtptoid and not($sttptoid)
    return <error rule="SD1103" variable="{data($sttptname)}" dataset="{$name}" rulelastupdate="2019-08-21">{data($sttptname)} is not present although {data($strtptname)} is present</error>			

