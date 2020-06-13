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

(: Rule CG0028: Except for TSSEQ, --SEQ is a unique number per USUBJID per domain, or a unique number per POOLID per domain :)
(: TODO: case when there is POOLID instead of USUBJID :)
(: TODO: must be done OVER datasets within the same domain :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;  
declare variable $define external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef
let $domain := $itemgroupdef/@Domain
let $itemgroupoid := $itemgroupdef/@OID
let $itemgroupname := $itemgroupdef/@Name
let $datasetname := $itemgroupdef/def:leaf/@xlink:href
let $datasets := concat($base,$datasetname) (: result is a set of datasets :)
(: get the OID of --SEQ, USUBJID :)
let $usubjidoid := 
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$itemgroupname]/odm:ItemRef/@ItemOID
    return $a 
let $seqoid := 
 	for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'SEQ') and not(@Name='TSSEQ')]/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$itemgroupname]/odm:ItemRef/@ItemOID
    return $a 
 (: get the Name of --SEQ :)
 let $seqname := doc(concat($base,$define))//odm:ItemDef[@OID=$seqoid]/@Name
(: now iterate over all datasets, but not the Trial design datasets and not for SUPPxx datasets :)
for $datasetdoc in doc($datasets)
   let $orderedrecords := (
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid] and odm:ItemData[@ItemOID=$seqoid]]
        group by 
        $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
        $c := $record/odm:ItemData[@ItemOID=$seqoid]/@Value
        return element group {  
            $record
        }
    )	
    for $group in $orderedrecords
        (: each group has the same values for USUBJID and --SEQ :)
        let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $seq := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$seqoid]/@Value
        let $recnums := $group/odm:ItemGroupData/@data:ItemGroupDataSeq
        (: for reporting the record number, we take the one of the last record in the group :)
        let $recnum := $group/odm:ItemGroupData[last()]/@data:ItemGroupDataSeq
        (: each group should only have one record. If not, there are duplicate values of USUBJID and --SEQ :)
        where count($group/odm:ItemGroupData) > 1
            return <error rule="CG0028" dataset="{data($itemgroupname)}" variable="{data($seqname)}" rulelastupdate="2020-06-09" recordnumber="{data($recnum)}">The record with USUBJID = {data($usubjid)} and {data($seqname)} is not unique in the dataset {data($itemgroupname)}. The following records have the same combination of USUBJID and {data($seqname)}: records number {data($recnums)}</error>	
	
	