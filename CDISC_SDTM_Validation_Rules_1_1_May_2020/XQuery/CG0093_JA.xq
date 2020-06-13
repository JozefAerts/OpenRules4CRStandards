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

(: Rule CG0093 - When --ELTM,  --TPTNUM,  and --TPT not present in dataset then --TPTREF not present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Applies to: all datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2) (: first 2 characters :)
    )
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    (: get the OID and name of --ELTM :)
    let $eltmoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: if there is no --ELTM, we do also not know its full name, so we must construct it :)
    let $eltmname := (
        if($eltmoid) then $definedoc//odm:ItemDef[@OID=$eltmoid]/@Name
        else concat($domain,'ELTM')
    )
    (: get the OID of --TPTNUM (if any) :)
    let $tptnumoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: if there is no --TPTNUM, we cannot know its full name, so we must then construct it :)
    let $tptnumname := (
        if($tptnumoid) then $definedoc//odm:ItemDef[@OID=$tptnumoid]/@Name
        else concat($domain,'TPTNUM')
    )
    (: get the OID of --TPT :)
    let $tptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: if there is no --TPT, we cannot know its full name, so we must then construct it :)
    let $tptname := (
        if($tptoid) then $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
        else concat($domain,'TPT')
    )
    (: get the OID and Name of --TPTREF :)
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name (: if there is an OID, then there is a name :)
    (: When --ELTM,  --TPTNUM,  and --TPT not present in dataset then --TPTREF not present in dataset :)
    where not($eltmoid) and not($tptnumoid) and not($tptoid) and $tptrefoid
    return
        <error rule="CG0093" rulelastupdate="2020-06-13" dataset="{data($name)}" variable="{data($tptrefname)}" >Variable {data($tptrefname)} is present in dataset {data($name)} although {data($eltmname)}, {data($tptnumname)} and {data($tptname)} are not present in the dataset</error>		
		
	