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

(: Rule CG0543: SE, PR, SM: --SEQ is in consistent chronological order :)
(: The rule does not say on what "chronological order" should be based on !!!
We will use --STDTC :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: sorting function - also sorts dates :)
declare function functx:sort
  ( $seq as item()* )  as item()* {
   for $item in $seq
   order by $item (: default is ascending :)
   return $item
 } ;
(: compare whether two sequences are equal :)
declare function functx:sequence-deep-equal
  ( $seq1 as item()* ,
    $seq2 as item()* )  as xs:boolean {
  every $i in 1 to max((count($seq1),count($seq2)))
  satisfies deep-equal($seq1[$i],$seq2[$i])
 } ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all SE, PR and SM datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='SE' or @Name='PR']
	let $name := $itemgroupdef/@Name
    (: We need the OIDs of USUBJID, --SEQ and --STDTC :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $seqoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SEQ')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the name of --SEQ and --STDTC for later reporting :)
    let $seqname := $definedoc//odm:ItemDef[@OID=$seqoid]/@Name
    let $stdtcname := $definedoc//odm:ItemDef[@OID=$stdtcoid]/@Name
    (: get the location of the dataset and the document itself :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
    	if($datasetlocation) then doc(concat($base,$datasetlocation))
        else ()
    )
    (: group all the records in the dataset by USUBJID :)
    let $groupedrecords := (
      for $record in $datasetdoc//odm:ItemGroupData
      group by 
          $a := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
          return element group {  
              $record
          }
	)
    (: iterate over all the groups, each group contains the records of a single subject :)
    for $group in $groupedrecords
    	(: get the value of USUBJID - all the records in the group have the same value for USUBJID :)
        let $usubjidvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    	(: ORDER the single records in the group by the value of --STDTC :)
        (: create an array with the --STDTC dates :)
        let $stdtcdates := $group/odm:ItemGroupData/odm:ItemData[@ItemOID=$stdtcoid]/@Value
    	let $sortedrecordsingroup := functx:sort($stdtcdates)
        (: the information in $stdtcdates and $sortedrecordsingroup must be identical. 
        If it isn't, the records are not in chronological order :)
        where not(functx:sequence-deep-equal($stdtcdates,$sortedrecordsingroup))
       	return <error rule="CG0543" dataset="{data($name)}" rulelastupdate="2020-08-04">Records for subject with USUBJID={data($usubjidvalue)} are not in correct chronological order by {data($seqname)} and {data($stdtcname)}</error>		
	
	