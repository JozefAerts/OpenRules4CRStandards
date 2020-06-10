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

(: Rule CG0193 - When MBTESTCD = 'ORGANISM' then MBRESCAT != null :)
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
(: get the MB dataset and its location :)
let $mbitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='MB']
let $mbdatasetlocation := $mbitemgroupdef/def:leaf/@xlink:href
let $mbdatasetdoc := doc(concat($base,$mbdatasetlocation))
(: get the OID of MBTESTCD and of MBRESCAT :)
let $mbtestcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBTESTCD']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $mbrescatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBRESCAT']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records for which MBTESTCD='ORGANISM' :)
for $record in $mbdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$mbtestcdoid and @Value='ORGANISM']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of MBRESCAT (if any) :)
    let $mbrescat := $record/odm:ItemData[@ItemOID=$mbrescatoid]/@Value
    (: When MBTESTCD = 'ORGANISM' then MBRESCAT != null :)
    where not($mbrescat)  (: meaning MBRESCAT=absent/null :)
    return <error rule="CG0193" dataset="MB" variable="MBRESCAT" rulelastupdate="2017-02-21" recordnumber="{data($recnum)}">MBTESTCD='ORGANISM' but MBRESCAT=null</error>	
     
    	