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
	
(: Rule CG0376 - TDSTOFF = 0 or positive value in ISO 8601 Duration format :)
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
(: Get the TD (Trial Disease) dataset :)
let $itemgroupdef := $definedoc//odm:ItemGroupDef[@Name='TD']
(: Get the location :)
let $datasetname := $itemgroupdef/def:leaf/@xlink:href
let $datasetlocation := concat($base,$datasetname)
let $datasetdoc := ( 
	if($datasetname) then doc($datasetlocation)
	else ()
)
(: get the OID of TDSTOFF :)
let $tdstoffoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TDSTOFF']/@OID 
    where $a = $itemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records for which TDSTOFF is populated :)
for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tdstoffoid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TDSTOFF :)
    let $tdstoff := $record/odm:ItemData[@ItemOID=$tdstoffoid]/@Value
    (: TDSTOFF must be either '0' or a non-negative duration :)
    where $tdstoff != '0' or starts-with($tdstoff,'-') or not($tdstoff castable as xs:duration)
    return <error rule="CG0376" dataset="TD" recordnumber="{data($recnum)}" variable="TDSTOFF" rulelastupdate="2020-06-18">TDSTOFF must either be '0' or a non-negative duration. TDSTOFF='{data($tdstoff)}' was found</error>			
		
	