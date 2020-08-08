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

(: Rule SD1283 - When --LOC not present in dataset then --LAT not present in dataset
Applies to: MI, MO, TU, VS, FA, SR, EX, EC, PR :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the MI, MO, TU, VS, FA, SR, EX, EC, PR :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Domain='MI' or starts-with(@Name,'MI') 
    or @Domain='MO' or starts-with(@Name,'MO') or @Domain='TU' or starts-with(@Name,'TU') 
    or @Domain='VS' or starts-with(@Name,'VS') or @Domain='FA' or starts-with(@Name,'FA')
    or @Domain='SR' or starts-with(@Name,'SR') or @Domain='EX' or starts-with(@Name,'EX')
    or @Domain='EC' or starts-with(@Name,'EC') or @Domain='EC' or starts-with(@Name,'EC')
    ]
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2) (: first 2 characters of name :)
    )
    (: get the OID of --LOC (if any) :)
    let $locoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'LOC') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the full name - in case there is no OID, we need to construct it :)
    let $locname := (
        if($locoid) then $definedoc//odm:ItemDef[@OID=$locoid]/@Name
        else concat($domain,'LOC')
    )
    (: get the OID and Name of --LAT :)
    (: get the OID of --LOC (if any) :)
    let $latoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'LAT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the full name - in case there is no OID, we need to construct it :)
    let $latname := (
        if($latoid) then $definedoc//odm:ItemDef[@OID=$latoid]/@Name
        else concat($domain,'LAT')
    )
    (: When --LOC not present in dataset then --LAT not present in dataset :)
    where not($locoid) and $latoid 
    return 
        <error rule="SD1283" rulelastupdate="2020-08-08" dataset="{data($name)}" variable="{data($latname)}">Variable {data($locname)} is absent in dataset {data($name)} but {data($latname)} is present in the dataset</error>
    	
	