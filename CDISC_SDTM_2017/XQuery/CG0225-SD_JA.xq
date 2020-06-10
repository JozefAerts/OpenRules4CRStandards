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

(: Rule CG0225  - When VISITNUM is NOT in TV.VISITNUM then VISITDY = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: declare variable $domain external; :)
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the location of the TV dataset :)
let $tvdataset := $definedoc//odm:ItemGroupDef[@Name='TV']/def:leaf/@xlink:href
let $tvdatasetlocation := concat($base,$tvdataset)
let $tvdatasetdoc := doc($tvdatasetlocation)
(: get the OID of the VISITNUM variable :)
let $tvvisitnumoid := (
    for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='TV']/odm:ItemRef/@ItemOID
        return $a   
)
(: create a sequence (array) VISITNUM in TV :)
let $tvvisitnums := $tvdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$tvvisitnumoid]/@Value
(: iterate over all other dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[not(@Name='TV')][@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: get the OID of VISITNUM and VISITDY (if any) :)
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $visitdyoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITDY']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the location of the dataset :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset for which there is a VISITNUM,
    but only when VISITDY and VISITNUM have been defined for this dataset :)
    for $record in $datasetdoc[$visitnumoid and $visitdyoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$visitnumoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of VISITNUM and of VISITDY (if any for the latter) :)
        let $visitnum := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value
        let $visitdy := $record/odm:ItemData[@ItemOID=$visitdyoid]/@Value
        (: When VISITNUM is NOT in TV.VISITNUM then VISITDY = null :)
        where not(functx:is-value-in-sequence($visitnum,$tvvisitnums)) and $visitdy (: the latter states that VISITDY is populated :)
        return <error rule="CG0225" dataset="{data($name)}" variable="VISITDY" rulelastupdate="2018-08-12" recordnumber="{data($recnum)}">VISITDY={data($visitdy)} is expected to be null as VISITNUM={data($visitnum)} is not present in TV</error>			
		
		