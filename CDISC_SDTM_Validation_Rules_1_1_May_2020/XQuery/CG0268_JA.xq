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

(: Rule CG0268 - When TSPARMCD not unique then TSSEQ is unique for each distinct value of TSPARMCD :)
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
(: iterate over all TS datasets - there should only be one :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TS']
    let $name := $datasetdef/@Name
    (: get the location of the dataset :)
    let $datasetname := $datasetdef/def:leaf/@xlink:href
    let $datasetlocation:= concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OIDs of TSPARMCD and TSSEQ :)
    let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsseqoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSSEQ']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: group the records by TSPARMCD :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid] and odm:ItemData[@ItemOID=$tsseqoid]]
            group by 
            $b := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
            return element group {  
                $record
            }
        ) 
    (: within each group, all the records have the same value for TSPARMCD :)
    for $group in $orderedrecords
        (: iterate over all records in the group :)
        for $record in $group/odm:ItemGroupData[odm:ItemData[@ItemOID=$tsseqoid]]
            let $recnum := $record/@data:ItemGroupDataSeq
            (: get the value of TSPARMCD and of TSSEQ :)
            let $tsparmcd := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
            let $tsseq := $record/odm:ItemData[@ItemOID=$tsseqoid]/@Value
            (: iterate over all subsequent records in the same group that have the same value of TSSEQ - there shouldn't be any :)
            for $recordduplicate in $record/following-sibling::odm:ItemGroupData[odm:ItemData[@ItemOID=$tsseqoid and @Value=$tsseq]]
                let $recnumduplicate := $recordduplicate/@data:ItemGroupDataSeq
                (: and give the error message :)
                return <error rule="CG0268" dataset="{data($name)}" variable="TSSEQ" rulelastupdate="2020-06-15">Inconsistent value for TSSEQ within TSPARMCD={data($tsparmcd)} in dataset {data($datasetname)}. Records {data($recnum)} and {data($recnumduplicate)} have the same value for TSSEQ={data($tsseq)}</error>			
		
	