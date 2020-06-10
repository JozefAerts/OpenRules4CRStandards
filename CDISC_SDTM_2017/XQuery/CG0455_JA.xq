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

(: Rule CG0455 - When TSPARMCD = 'PCLAS' then TSVCDREF = 'NDF-RT' :)
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
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD variable :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of the TSVCDREF variable :)
let $tsvcdrefoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVCDREF']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records that have TSPARMCD=PCLAS :)
for $record in doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='PCLAS']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the value of TSVCDREF :)
    let $tsvcdrefvalue := $record/odm:ItemData[@ItemOID=$tsvcdrefoid]/@Value
    (: the value of TSVCDREF MUST be 'NDF-RT' :)
    where not($tsvcdrefvalue='NDF-RT')
    return <error rule="CG0455" dataset="TS" variable="TSVCDREF" rulelastupdate="2017-03-24" recordnumber="{data($recnum)}">Invalid TSVCDREF value={data($tsvcdrefvalue)} for TSPARMCD=PCLAS. The value must be 'NDF-RT'</error>				
		
		