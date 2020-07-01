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
	
(: Rule SD2017 - Missing TSVAL value
Value for Parameter Value (TSVAL) variable must be populated. TSVAL can only be null when Parameter Null Flavor (TSVALNF) variable value is populated.
:)
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

(: Get the TS dataset :)
let $tsdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: Get the OIDs of TSVAL and TSVALNF :)
let $tsvaloid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TSVAL')]/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalnfoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TSVALNF')]/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: Iterate over all the records in the TS dataset :)
for $record in doc($tsdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSVAL and TSVALNF (if any) :)
    let $tsvalvalue := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    let $tsvalnfvalue := $record/odm:ItemData[@ItemOID=$tsvalnfoid]/@Value
    (: check whether TSVAL is populated except for when TSVALNF is populated :)
    where not($tsvalnfvalue) and not($tsvalvalue)
    return <error rule="SD2017" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">Missing TSVAL value</error>
