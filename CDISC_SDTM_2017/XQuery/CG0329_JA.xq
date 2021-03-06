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

(: Rule CG0239 - When TEENRL = null then TEDUR ^= null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the TE dataset definition and location :)
let $teitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TE']
let $tedatasetlocation := $teitemgroupdef/def:leaf/@xlink:href
let $tedatasetdoc := doc(concat($base,$tedatasetlocation))
(: we need the OIDs of TEDUR and TEENRL :)
let $teduroid := (
    for $a in $definedoc//odm:ItemDef[@Name='TEDUR']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $teenrloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TEENRL']/@OID
    where $a = $teitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all the records in the dataset for which TEENRL=null :)
for $record in $tedatasetdoc//odm:ItemGroupData[not(odm:ItemData/@ItemOID=$teenrloid)]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TEDUR :)
    let $tedur := $record/odm:ItemData[@ItemOID=$teduroid]/@Value
    (: TEDUR may not be null :)
    where not($tedur)
    return <error rule="CG0329" dataset="TE" recordnumber="{data($recnum)}" rulelastupdate="2017-03-11">TEDUR is null although TEENRL is null</error>			
		
		