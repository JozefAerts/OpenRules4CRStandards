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

(: Rule SD1212 - --STRESN does not equal --STRESC when --STRESC represents a number - FINDINGS domains
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'
let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all the FINDINGS datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Find the OID of the --STRESN variable  :)
    let $stresnoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRESN')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the name :)
    let $stresnname := doc(concat($base,$define))//odm:ItemDef[@OID=$stresnoid]/@Name
    (: Find the OID and the name of the --STRESC variable :)
    let $strescoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strescname := doc(concat($base,$define))//odm:ItemDef[@OID=$strescoid]/@Name
    (: iterate over all the records in the dataset :)
    (: TODO: to speed things up, an "IF" is needed here :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the value of the STRESC variable :)
        let $strescvalue := $record/odm:ItemData[@ItemOID=$strescoid]/@Value
        (: and of the STRESN variable (if any) :)
        let $stresnvalue := $record/odm:ItemData[@ItemOID=$stresnoid]/@Value
        (: check whether the value of --STRESC is representing a numeric value :)
        (: when --STAT exists and --STAT=null ensure there is a STRESC data point :)
        where $strescvalue castable as xs:double and xs:double($strescvalue) != xs:double($stresnvalue)
        return <warning rule="SD1212" rulelastupdate="2019-08-16" dataset="{data($name)}" variable="{data($stresnname)}" recordnumber="{data($recnum)}">Value for {data($stresnname)} '{data($stresnvalue)}' does not equal value for {data($strescname)} '{data($strescvalue)}'</warning>	

