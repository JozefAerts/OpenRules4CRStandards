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

(: Rule CG0467 - --STDTC not present in FINDINGS datasets :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $itemgroupdef/@Name
    let $domain := substring($name,1,2)
    let $stdtcname := concat($domain,'STDTC')
    (: get the OID of --STDTC (when present) :)
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC') and string-length(@Name)=7]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: --STDTC may not be present :)
    where $stdtcoid
    return <error rule="CG0467" dataset="{data($name)}" variable="" rulelastupdate="2020-06-19">Variable {data($stdtcname)} is not allowed to be present in the FINDINGS dataset {data($name)}</error>													
		
	