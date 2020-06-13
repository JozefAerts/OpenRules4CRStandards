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

(: Rule CG0058 when --ENRTPT present in dataset present in dataset then --ENTPT must be present in dataset :)
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
(: Iterate over all datasets defined in the define.xml :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else $name
    )
    (: find the OID and name of the --ENTPT variable /(if any) :)
    let $entptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $entptname := concat($domain,'ENTPT') (: as when --ENTPT is absent, we also do not know its name  :)
    (: and of the --ENRTPT variable :)
    let $enrtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := $definedoc//odm:ItemDef[@OID=$enrtptoid]/@Name
    (: when --ENRTPT present in dataset then --ENTPT must present in dataset :)
    where $enrtptoid and not($entptoid)
    return <error rule="CG0058" variable="{data($entptname)}" dataset="{$name}" rulelastupdate="2020-06-11">{data($entptname)} is not present although {data($enrtptname)} is present</error>	
		
	