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
	
(: Rule SD1068 - Duplicate ELEMENT value:
The value of Element (Description of Element) variable must be unique within Trial Elements (TE) domain
:)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))  
(: get the TE dataset :)
let $tedataset := $definedoc//odm:ItemGroupDef[@Name='TE']
let $tedatasetname := (
	if($defineversion = '2.1') then $tedataset/def21:leaf/@xlink:href
	else $tedataset/def:leaf/@xlink:href
)
let $tedatasetlocation := concat($base,$tedatasetname)
(: get the OID of the ELEMENT variable :)
let $elementoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ELEMENT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the TE dataset :)
for $record in doc($tedatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of ELEMENT :)
    let $elementvalue := $record//odm:ItemData[@ItemOID=$elementoid]/@Value
    (: iterate over all following records :)
    for $record2 in doc($tedatasetlocation)//odm:ItemGroupData[@data:ItemGroupDataSeq > $recnum]
        (: and compare the value of ELEMENT in the record with the original one :)
        let $recnum2 := $record2/@data:ItemGroupDataSeq
        let $elementvalue2 := $record2//odm:ItemData[@ItemOID=$elementoid]/@Value
        where $elementvalue=$elementvalue2
        return <warning rule="SD1068" dataset="TE" variable="ELEMENT" rulelastupdate="2020-08-08" recordnumber="{data($recnum2)}">Duplicate ELEMENT value: records {data($recnum)} and {data($recnum2)} have the same value for ELEMENT, value={data($elementvalue)}</warning>
