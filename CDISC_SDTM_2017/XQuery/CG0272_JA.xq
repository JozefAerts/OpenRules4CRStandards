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

(: Rule CG0272 - When TSPARMCD = 'TDIGRP'  and record exists where TSPARMCD = 'HLTSUBJI' and TSVAL = 'Y' then TSVAL = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVAL and TSPARMCD variables :)
    let $tsvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsparmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset :)
    let $datasetname := $itemgroup//def:leaf/@xlink:href
    let $dataset := concat($base,$datasetname)
    let $datasetdoc := doc($dataset)
    (: look for a record with TSPARMCD='HLTSUBJI' and TSVAL='Y' :)
    let $hltsubjects := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='HLTSUBJI'] and odm:ItemData[@ItemOID=$tsvaloid and @Value='Y']]  (: the record itself or null :)
    (: look for a record with TSPARMCD='TDIGRP' :)
    let $tdigrprecord :=  $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='TDIGRP']]
    let $recnum := $tdigrprecord/@data:ItemGroupDataSeq
    let $tdigrpvalue := $tdigrprecord/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    (: TSPARMCD = 'TDIGRP' must be null :)
    where $hltsubjects and (not($tdigrpvalue) or string-length($tdigrpvalue)=0 )
    return <error rule="CG0272" dataset="TS" variable="TSVAL" rulelastupdate="2017-02-26">TSVAL='{data($tdigrpvalue)}' for TSPARMCD='TDIGRP' is expected to be null as a record with TSPARMCD='HLTSUBJI and TSVAL='Y' exists</error>		
		