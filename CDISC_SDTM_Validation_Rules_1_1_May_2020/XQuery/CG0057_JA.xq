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

(: Rule CG0057 when --ENTPT present in dataset present in dataset then --ENRTPT must be present in dataset :)
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
    let $entptname := $definedoc//odm:ItemDef[@OID=$entptoid]/@Name
    (: and of the --ENRTPT variable :)
    let $enrtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := concat($domain,'ENRTPT') (: as when --ENRTPT is absent, we also do not know its name  :)
    (: when --ENTPT present in dataset then --ENRTPT must present in dataset :)
    where $entptoid and not($enrtptoid)
    return <error rule="CG0057" variable="{data($enrtptname)}" dataset="{$name}" rulelastupdate="2020-08-04">{data($enrtptname)} is not present although {data($entptname)} is present</error>	
		
	