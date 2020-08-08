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

(: Rule SD1026 - Invalid value for RELTYPE variable: 
Relationship Type (RELTYPE) in RELREC must be NULL, when Identifying Variable (IDVAR) is populated with a --SEQ value
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
(: Get the RELREC dataset :)
let $relrecdataset := $definedoc//odm:ItemGroupDef[@Name='RELREC']
let $relrecdatasetname := (
	if($defineversion = '2.1') then $relrecdataset/def21:leaf/@xlink:href
	else $relrecdataset/def:leaf/@xlink:href
)
let $relrecdatasetlocation := concat($base,$relrecdatasetname)
(:  and the OID of RELID and of the IDVAR :)
let $reltypeoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RELTYPE']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
    return $a
)
let $idvaroid := (
    for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
    return $a
)
(: now iterate over all the records in the RELREC dataset :)
for $record in doc($relrecdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    let $idvarvalue := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
    let $relvalue := $record/odm:ItemData[@ItemOID=$reltypeoid]/@Value
    (: and check those that have IDVAR ending with 'SEQ' - for these RELTYPE must be null :)
    where ends-with($idvarvalue,'SEQ') and string-length($relvalue) > 0 
    return <error rule="SD1026" dataset="RELREC" variable="RELTYPE" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Invalid value for RELTYPE variable. Non-null value={data($relvalue)} was found though identifying variable is {data($idvarvalue)}</error>
