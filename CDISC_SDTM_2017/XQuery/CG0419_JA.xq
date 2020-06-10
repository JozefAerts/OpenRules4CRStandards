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

(: Rule CG0419 - When IDVAR populated with a --SEQ value then RELTYPE = null :)
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
(: Get the RELREC dataset :)
let $relrecitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='RELREC']
let $relrecdatasetlocation := $relrecitemgroupdef/def:leaf/@xlink:href
let $relrecdoc := doc(concat($base,$relrecdatasetlocation))
(:  and the OID of IDVAR and of RELTYPE :)
let $idvaroid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='IDVAR']/@OID 
    where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $reltypeoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RELTYPE']/@OID 
    where $a = $relrecitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all the records in the RELREC dataset  :)
for $record in $relrecdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of IDVAR and of RELTYPE (if any)  :)
    let $idvar := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
    let $reltype := $record/odm:ItemData[@ItemOID=$reltypeoid]/@Value
    (: when IDVAR is a --SEQ, the RELTYPE must be null :)
    where ends-with($idvar,'SEQ') and $reltype 
    return <error rule="CG0419" dataset="RELREC" variable="RELTYPE" rulelastupdate="2017-03-22" recordnumer="{data($recnum)}">IDVAR={data($idvar)} but RELTYPE is not null. RELTYPE='{data($reltype)}' is found</error>				
		
		