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

(: Rule SD2242: Invalid TSVCDREF value for TRT: TSVCDREF variable value must be 'UNII', when  TSPARMCD='TRT' :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the TS dataset :)
let $tsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion = '2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdataset := doc(concat($base,$tsdatasetname))
(: get the OID of the TSPARMCD variable :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of the TSVCDREF variable :)
let $tsvcdrefoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVCDREF']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: Now iterate over all records in the TS dataset for which TSPARMCD='TRT' :)
for $record in $tsdataset//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='TRT']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSVCDREF :)
    let $tsvcdref := $record/odm:ItemData[@ItemOID=$tsvcdrefoid]/@Value
    (: The value must be UNII  :)
    where not($tsvcdref='UNII')
    (: TODO: what if TSVCDREF is absent? This currently also gives an error :)
    return  <error rule="SD2242" dataset="TS" variable="TSVCDREF" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid TSVCDREF value for TRT: TSVCDREF variable value must be 'UNII', when  TSPARMCD='TRT', value found is '{data($tsvcdref)}'</error>
