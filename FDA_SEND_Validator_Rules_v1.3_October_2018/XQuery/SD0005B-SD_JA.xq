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

(: Rule SD0005 The value of Sequence Number (--SEQ) variable must be unique for each record within a domain and within each Pool Identifier (POOLID) variable value when they are present in the domain :)
(: SD0005A implements the rule for USUBJID, SD0005B implements the rule for POOLID :)
(: TODO: must be done OVER datasets within the same domain :)
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
declare variable $datasetname external;
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
(: let $datasetname := 'FW' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the provided dataset(s) :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
	let $domain := $itemgroupdef/@Domain
	let $itemgroupoid := $itemgroupdef/@OID
	let $itemgroupname := $itemgroupdef/@Name
	let $dsname := (
	if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
  let $datasets := concat($base,$dsname) (: result is a set of datasets - but in this case only 1 :)
  (: get the OID of --SEQ and POOLID :)
  let $seqoid := 
      for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SEQ') and string-length(@Name)=5]/@OID 
      where $a = $definedoc//odm:ItemGroupDef[@Name=$itemgroupname]/odm:ItemRef/@ItemOID
      return $a 
  let $poolidoid := 
      for $a in $definedoc//odm:ItemDef[@Name='POOLID']/@OID 
      where $a = $definedoc//odm:ItemGroupDef[@Name=$itemgroupname]/odm:ItemRef/@ItemOID
      return $a 
  (: get the Name of --SEQ :)
  let $seqname := $definedoc//odm:ItemDef[@OID=$seqoid]/@Name
  (: now iterate over all datasets, but not the Trial design datasets and not for SUPPxx datasets :)
  for $datasetdoc in doc($datasets)
     let $orderedrecords := (
      for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$poolidoid] and odm:ItemData[@ItemOID=$seqoid]]
          group by 
          $b := $record/odm:ItemData[@ItemOID=$poolidoid]/@Value,
          $c := $record/odm:ItemData[@ItemOID=$seqoid]/@Value
          return element group {  
              $record
          }
      )	
      for $group in $orderedrecords
          (: each group has the same values for POOLID and --SEQ :)
          let $poolid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$poolidoid]/@Value
          let $seq := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$seqoid]/@Value
          let $recnums := $group/odm:ItemGroupData/@data:ItemGroupDataSeq
          (: for reporting the record number, we take the one of the last record in the group :)
          let $recnum := $group/odm:ItemGroupData[last()]/@data:ItemGroupDataSeq
          (: each group should only have one record. If not, there are duplicate values of POOLID and --SEQ :)
          where count($group/odm:ItemGroupData) > 1
              return <error rule="SD0005" dataset="{data($itemgroupname)}" variable="{data($seqname)}" rulelastupdate="2019-08-20" recordnumber="{data($recnum)}">The record with POOLID = {data($poolid)} and {data($seqname)} is not unique in the dataset {data($itemgroupname)}. The following records have the same combination of POOLID and {data($seqname)}: records number {data($recnums)}</error>
