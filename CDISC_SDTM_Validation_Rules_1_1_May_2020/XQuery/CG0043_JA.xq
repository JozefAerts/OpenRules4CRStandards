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
	
(: Rule CG0043: when AESMIE='Y' then a record must present in SUPPAE where SUPPAE.QNAM=AESOSP  :)
(: ATTENTION: there seems to be an error in the Excel worksheet: condition and precondition seem to have been interchanged  :)
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
(: define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the SUPPAE dataset - there should only be one :)
let $suppaedataset := $definedoc//odm:ItemGroupDef[@Name='SUPPAE']
let $suppaedatasetlocation := $suppaedataset/def:leaf/@xlink:href
let $suppaedoc := doc(concat($base,$suppaedatasetlocation))
(: we need the OIDs of QNAM and QVAL and of USUBJID :)
let $suppaeusubjidoid := (
  for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
  where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
  return $a 
)
let $qnamoid := (
  for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID 
  where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
  return $a 
)
let $qvaloid := (
  for $a in $definedoc//odm:ItemDef[@Name='QVAL']/@OID 
  where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
  return $a 
)
(: and, just to be sure, of IDVAR and IDVARVAL :)
let $idvaroid := (
  for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
  where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
  return $a 
)
let $idvarvaloid := (
  for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
  where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
  return $a 
)
(: iterate over the AE datasets (for the case there is more than 1) :)
for $dataset in $definedoc//odm:ItemGroupDef[@Domain='AE' or starts-with(@Name,'AE')]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OIDs of AESEQ and USUBJID :)
    let $usubjidoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aeseqoid := (
    	for $a in $definedoc//odm:ItemDef[@Name='AESEQ']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: and get the OID of AESMIE :)
    let $aesmieoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESMIE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: Although the rule does not state this explicitly, 
    	we take AESEQ as identifier in the SUPPAE  :)
    (: iterate over all the records :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of USUBJID and AESEQ :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $aeseq := $record/odm:ItemData[@ItemOID=$aeseqoid]/@Value
        (: get the value of the AESMIE (when present) :)
        let $aesmievalue := $record/odm:ItemData[@ItemOID=$aesmieoid]/@Value
        (: when AESMIE='Y' then a record must present in SUPPAE where SUPPAE.QNAM=AESOSP :)
        let $suppaeaesosprecord := $suppaedoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$suppaeusubjidoid]/@Value=$usubjid and odm:ItemData[@ItemOID=$idvaroid]/@Value='AESEQ' and odm:ItemData[@ItemOID=$idvaroid]/@Value=$aeseq and  odm:ItemData[@ItemOID=$qnamoid]/@Value='AESOSP']
       	where $aesmievalue='Y' and not($suppaeaesosprecord)
        return <error rule="CG0043" dataset="{data($name)}" variable="AESMIE" rulelastupdate="2020-06-11" recordnumber="{data($recnum)}">No SUPPAE record 'AESOSP' was found for the AE record with AESMIE='{data($aesmievalue)}'</error>			 	
	
	