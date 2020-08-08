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
	
(: Rule SD2018 - Missing TSVALNF value
Value for Parameter Null Flavor (TSVALNF) variable must be populated, when Parameter Value (TSVAL) variable value is missing.
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
(: Get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion = '2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: Get the OIDs of TSVAL and TSVALNF :)
let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TSVAL')]/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalnfoid := (
    for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TSVALNF')]/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: Iterate over all the records in the TS dataset :)
for $record in doc($tsdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSVAL and TSVALNF (if any) :)
    let $tsvalvalue := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    let $tsvalnfvalue := $record/odm:ItemData[@ItemOID=$tsvalnfoid]/@Value
    (: check whether TSVAL is populated except for when TSVALNF is populated :)
    where not($tsvalvalue) and not($tsvalnfvalue)
    return <error rule="SD2018" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Missing TSVALNF value</error>	
