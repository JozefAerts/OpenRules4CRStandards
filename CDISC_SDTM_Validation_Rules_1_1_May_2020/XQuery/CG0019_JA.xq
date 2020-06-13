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

(: Rule CG0019: Each record is unique per sponsor defined key variables as documented in the define.xml :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) of values :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: iterate over all datasets in the define.xml :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef
    (: get the domain name - value of the 'Domain' attribute :)
    let $domain := $itemgroup/@Domain
    (: and the dataset name (@Name attribute) :)
    let $name := $itemgroup/@Name
    (: and get the filename and the corresponding document :)
    let $filename := $itemgroup/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$filename))
    (: get the keys - the following assumes define-XML 2.0 :)
    let $keyoids := $itemgroup/odm:ItemRef[@KeySequence]/@ItemOID
    (: worst case scenario there are no keys defined :)
    return
    if (count($keyoids) = 0) then
        <error rule="CG0019" dataset="{data($name)}" rulelastupdate="2020-06-08">No keys have been defined for dataset  {data($name)} in the define.xml!</error>
    else 
    (: we now have the OIDs of the key variables, and that is exactly what we need when working with Dataset-XML :)
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData 
        let $recordnum := $record/@data:ItemGroupDataSeq  (: the record number :)
        (: create a sequence (array) with the VALUES of the key variables :)
        let $keyvalues := (
            (: we need the value of the attribute, not the attribute itself, therefore we need the data() function :)
            for $value in $record/odm:ItemData[functx:is-value-in-sequence(@ItemOID,$keyoids)]/@Value return data($value)  
        )
        (: TESTING: for $item in $keyvalues return <test>{$item}</test> :)
        (: iterate over the next records and do the same :)
        for $record2 in $datasetdoc//odm:ItemGroupData[@data:ItemGroupDataSeq > $recordnum]
            let $recordnum2 := $record2/@data:ItemGroupDataSeq  (: the record number :)
            (: create a sequence (array) with the VALUES of the key variables :)
            let $keyvalues2 := (
                (: we need the value of the attribute, not the attribute itself, therefore we need the data() function :)
                for $value in $record2/odm:ItemData[functx:is-value-in-sequence(@ItemOID,$keyoids)]/@Value return data($value)  
            )
            (: compare the two sequences (array), if the contents are equal, this is an error (duplicate records) :)
            where functx:sequence-deep-equal($keyvalues,$keyvalues2)
            return <error rule="CG0019" dataset="{data($name)}" rulelastupdate="2020-06-08">Records {data($recordnum)} and {data($recordnum2)} have the same values for the key variables as defined in the define.xml</error>			
			
	