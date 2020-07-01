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

(: Rule SD0064 FAST ALTERNATIVE - All Subjects (USUBJID) must be present in Demographics (DM) domain :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
 } ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: request-parameter allows to pass $base from an external programm :)
(: let $base:= request:get-parameter("mybase","/db/fda_submissions/cdiscpilot01/") :)
(: let $define := request:get-parameter("mydefine","define_2_0.xml")  :)
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: we need the ItemOID of the USUBJID variable - and need to take care of the use case that people have used different ItemDefs for the same variable in
different domains/datasets :)
(: first get the one for the DM dataset :)
(: let $dmitemgroupdef := doc(concat($base,$define)) :)
let $dmitemgroupdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
let $dmdatasetname := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetpath := concat($base,$dmdatasetname)
(: this assumes that the third variable in the DM is USUBJID (which essentially always should be the case :)
let $usubjoiddm := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: and all the values in the DM dataset :)
let $usubjiddm := doc($dmdatasetpath)//odm:ItemData[@ItemOID=$usubjoiddm]/@Value
(: now iterate over all dataset definitions in the define.xml and get the USUBJID :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef
    let $dataset := $itemgroupdef/def:leaf/@xlink:href
    let $datasetname := $itemgroupdef/@Name
    let $datasetpath := concat($base,$dataset)
    (: find the variable for which the name is 'USUBJID' - there should be 0 or 1 :)
    let $usubjidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    for $d in doc($datasetpath)//odm:ItemGroupData[odm:ItemData[@ItemOID=$usubjidoid]]
        let $recnum := $d/@data:ItemGroupDataSeq
        let $value := $d/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: check whether it DM-USUBJID :)
        where not(functx:is-value-in-sequence($value,$usubjiddm))
        return <error rule="SD0064" rulelastupdate="2019-08-20" dataset="{data($datasetname)}" variable="USUBJID"  recordnumber="{data($recnum)}">USUBJID {data($value)} in dataset {data($datasetname)} could not be found in DM dataset</error>
