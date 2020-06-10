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
	
(: Rule CG0369 - When RDOMAIN != null then RDOMAIN is dataset in study (SUPP--, CO, RELREC) :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: make a list of all domain names in the submission :)
let $domains := (
    for $itemgroupdef in $definedoc//odm:ItemGroupDef[not(@Name='CO' or @Name='RELREC' or starts-with(@Name,'SUPP'))]
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($itemgroupdef/@Name,1,2)  (: first 2 characters of the dataset :)
    )
    return $domain
)
(: iterate over all SUPP--, CO and RELREC dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='CO' or @Name='RELREC' or starts-with(@Name,'SUPP')]
    let $name := $itemgroupdef/@Name
    (: get the OID of RDOMAIN :)
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and the document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset for which there is a value of RDOMAIN :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rdomainoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of RDOMAIN :)
        let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        where not(functx:is-value-in-sequence($rdomain,$domains))
        return <error rule="CG0369" dataset="{data($name)}" variable="RDOMAIN" recordnumber="{data($recnum)}" rulelastupdate="2017-03-15">Value of RDOMAIN='{data($rdomain)}' was not found as a dataset in the submission</error>			
		
		