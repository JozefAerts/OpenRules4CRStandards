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

(: Rule SD1067 - USUBJID value is populated, when RELTYPE values is populated:
Unique Subject Identifier (USUBJID) variable value should not be populated, when Relationship Type (RELTYPE) variable value is populated in RELREC
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
(: Get the location of the RELREC dataset :)
let $relrecdatasetname := (
	if($defineversion = '2.1') then $definedoc//odm:ItemGroupDef[@Name='RELREC']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='RELREC']/def:leaf/@xlink:href
)
let $relrecdatasetlocation := concat($base,$relrecdatasetname)
(: Get the OID of the RELTYPE and USUBJID variable :)
let $reltypeoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RELTYPE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
        return $a 
)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
        return $a 
)
(: iterate over all records in the dataset :)
for $record in doc($relrecdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values of RELTYPE and USUJID (when present) :)
    let $reltypevalue := $record/odm:ItemData[@ItemOID=$reltypeoid]/@Value
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: Unique Subject Identifier (USUBJID) variable value should not be populated, 
    when Relationship Type (RELTYPE) variable value is populated in RELREC :)
    where $reltypevalue and $usubjidvalue
    return <warning rule="SD1067" dataset="RELREC" variable="USUBJID" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">USUBJID value is populated (value={data($usubjidvalue)}), when RELTYPE values is populated (value={data($reltypevalue)}) in dataset {data($relrecdatasetname)}</warning>
