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
	
(: Rule SD0089 - Missing values for TEENRL and TEDUR
At least one of Rule for End of Element (TEENRL) or Planned Duration of Element (TEDUR) should be populated in TE
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: Get the location of the TE dataset :)
let $tedataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TE']
let $tedatasetname := $tedataset/def:leaf/@xlink:href
let $tedatasetdoc := (
	if($tedatasetname) then doc(concat($base,$tedatasetname))
	else ()
)
(: and get the OIDs of TEENRL and TEDUR in TE :)
let $teenrloid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TEENRL']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
        return $a
)
let $teduroid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TEDUR']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TE']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records in the TE dataset :)
for $record in $tedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values for TEENRL and TEDUR (if any) :)
    let $teenrlvalue := $record/odm:ItemData[@ItemOID=$teenrloid]/@Value
    let $tedurvalue := $record/odm:ItemData[@ItemOID=$teduroid]/@Value
    (: at least one must be populated :)
    where not($teenrlvalue) and not($tedurvalue)
    return <warning rule="SD0089" dataset="TE" rulelastupdate="20189-08-30" recordnumber="{data($recnum)}">Missing values for TEENRL and TEDUR</warning>