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

(: Rule SD0082: Exposure end date is after the latest Disposition date: 
End Date/Time of Treatment (EXENDTC) should be less than or equal to the Start Date/Time of the latest Disposition Event (DSSTDTC) :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: Get the DS dataset :)
let $dsdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DS']/def:leaf/@xlink:href
let $dsdataset := concat($base,$dsdatasetname)
(: and the OID of the USUBJID :) 
let $dsusubjoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
    return $a
)
let $dsstdtcoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
    return $a
)
(: Get the EX dataset :)
let $exdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='EX']/def:leaf/@xlink:href
let $exdataset := concat($base,$exdatasetname)
let $exusubjidoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='EX']/odm:ItemRef/@ItemOID
    return $a
)
let $exendtcoid := doc(concat($base,$define))//odm:ItemDef[@Name='EXENDTC']/@OID
(: iterate over all the records in the EX dataset :)
for $exrecord in doc($exdataset)//odm:ItemGroupData
    let $recnum := $exrecord/@data:ItemGroupDataSeq
    (: get als well the USUBJID as the EXENDTC :)
    let $exusubjidvalue := $exrecord/odm:ItemData[@ItemOID=$exusubjidoid]/@Value
    let $exendtcvalue := $exrecord/odm:ItemData[@ItemOID=$exendtcoid]/@Value
    (: now get the latest (maximal) value DSSTDTC in the DS dataset for this subject :)
    (: let $lastdssdtcvalue := max(doc($dsdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjoid and @Value=$exusubjidvalue]]/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value) :)
    let $dssdtcvalues := doc($dsdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjoid and @Value=$exusubjidvalue]]/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
    (: get the latest DSSTDTC date :)
    let $latestdate := max(for $date in $dssdtcvalues return xs:date($date))
    (: and report an error when DSSTDTC before EXENDTC  :)
    (: remark that we need to test first whether there is an actual EXENDTC value :)
    where $exendtcvalue and xs:date($latestdate) < xs:date($exendtcvalue) 
    return <warning rule="SD0082" dataset="EX" variable="EXENDTC" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">Exposure end date EXENDTC={data($exendtcvalue)} for USUBJID={data($exusubjidvalue)} is after last disposition date {data($latestdate)}</warning>
