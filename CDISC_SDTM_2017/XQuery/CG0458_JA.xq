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

(: Rule CG0458 - When TSPARMCD in ('INDIC', 'TDIGRP') then TSVCDREF = 'SNOMED'  :)
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
let $tsdatasetdoc := doc(concat($base,$tsdatasetname))
(: get the OID of the TSPARMCD and TSVCDREF :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvcdrefoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVCDREF']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all the records for which TSPARMCD is either 'INDIC' or 'TDIGRP' :)
for $record in $tsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and(@Value='INDIC' or @Value='TDIGRP')]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSVCDREF and of TSPARMCD :)
    let $tsvcdrefvalue := $record/odm:ItemData[@ItemOID=$tsvcdrefoid]/@Value
    let $tsparmcdvalue := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
    (: TSVCDREF must be 'SNOMED' :)
    where not($tsvcdrefvalue='SNOMED')
    return <error rule="CG0458" dataset="TS" variable="TSVCDREF" rulelastupdate="2017-03-24" recordnumber="{data($recnum)}">Invalid TSVCDREF value '{data($tsvcdrefvalue)}' for Trial Summary Parameter TSPARMCD={data($tsparmcdvalue)} in dataset {data($tsdatasetname)}</error>				
		
		