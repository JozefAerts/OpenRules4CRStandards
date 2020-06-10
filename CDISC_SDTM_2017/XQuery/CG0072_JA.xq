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

(: Rule CG0072 When DS.DSDECOD = 'PROTOCOL DEVIATION' and DV exists then DV record present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the DS dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Get the DV dataset and its location :)
let $dvitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DV']
let $dvdatasetlocation := $dvitemgroupdef/def:leaf/@xlink:href
let $dvdatasetdoc := doc(concat($base,$dvdatasetlocation))
(: get the OID of USUBJID and of DSDECOD in DS :)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of USUBJID and of DTHDTC in DS :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of USUBJID in DV (can be different from the one in DS) :)
let $dvusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dvitemgroupdef/odm:ItemRef/@ItemOID
    return $a    
)
(: Iterate over all records that have DSDECOD='PROTOCOL DEVIATION', 
but only when there is a DV dataset, otherwise it does not make sense (precondition) :)
for $record in $dsdatasetdoc[doc-available($dvdatasetdoc)]//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsdecodoid and @Value='PROTOCOL DEVIATION']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the USUBJID :)
    let $usubjid := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
    (: and find whether there is a record in DV :)
    let $dvrecord := $dvdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dvusubjidoid and @Value=$usubjid]]
    (: there must be record in DV :)
    where not($dvrecord)
    return <error rule="CG0072" dataset="DV" rulelastupdate="2017-02-08" recordnumber="{data($recnum)}">No record in DV could be found for record 'PROTOCOL DEVIATION' record in DS for USUBID={data($usubjid)}</error>		
		