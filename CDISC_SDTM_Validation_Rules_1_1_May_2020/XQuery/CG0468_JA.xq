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

(: Rule CG0468 - -When --TPT present in dataset then --TPTNUM present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := substring($name,1,2)
    let $stdtcname := concat($domain,'STDTC')
    (: get the OID of --TPT :)
    let $tptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    (: get the OID of --TPTNUM (when present) :)
    let $tptnumoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM') and string-length(@Name)=8]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptnumname := concat($domain,'TPTNUM') (: we use the concatenation here as it can be that the OID is null :)
    (: --TPTNUM msut be present when --TPT is present :)
    where $tptoid and not($tptnumoid)
    return <error rule="CG0468" dataset="{data($name)}" variable="" rulelastupdate="2020-08-04">Variable {data($tptnumname)} is absent although {data($tptname)} is present</error>													
		
	