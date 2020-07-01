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
	
(: Rule SD1066 - IDVARVAL value is populated, when RELTYPE values is populated:
Variable Value (IDVARVAL) variable value should not be populated, when Relationship Type (RELTYPE) variable value is populated
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

(: Get the location of the RELREC dataset :)
let $relrecdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='RELREC']/def:leaf/@xlink:href
let $relrecdatasetlocation := concat($base,$relrecdatasetname)
(: and get the OIDs of the IDVARVAL and RELTYPE variables :)
let $idvarvaloid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
        return $a 
)
let $reltypeoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RELTYPE']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='RELREC']/odm:ItemRef/@ItemOID
        return $a     
)
(: iterate over all the records in the dataset :)
for $record in doc($relrecdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the IDVARVAL and RELTYPE data points :)
    let $idvarvalvalue := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
    let $reltypevalue := $record/odm:ItemData[@ItemOID=$reltypeoid]/@Value
    (: Variable Value (IDVARVAL) variable value should not be populated, when Relationship Type (RELTYPE) variable value is populated :)
    where $reltypevalue and $idvarvalvalue
    return <warning rule="SD1066" dataset="RELREC" variable="IDVARVAL" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">IDVARVAL value is populated (value={data($idvarvalvalue)}, when RELTYPE values is populated (value={data($reltypevalue)})</warning>
