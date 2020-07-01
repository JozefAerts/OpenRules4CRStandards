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

(: Rule SD1250 - When --TPTNUM present in dataset then --TPT must be present in dataset :)
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
    (: get the OID and name of --TPT :)
    let $tptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    (: get the OID of --TPTNUM (if any) :)
    let $tptnumoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: if there is no --TPTNUM, we cannot know its full name, so we must then construct it :)
    let $tptnumname := (
        if($tptnumoid) then $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
        else concat($domain,'TPTNUM')
    )
    (: When --TPT present in dataset then --TPTNUM must be present in dataset :)
    where $tptoid and not($tptnumoid)
    return
        <error rule="SD1250" rulelastupdate="2019-09-05" dataset="{data($name)}" variable="{data($tptnumname)}" >Variable {data($tptname)} is present in dataset {data($name)} but {data($tptnumname)} is not present in the dataset</error>			
		
	