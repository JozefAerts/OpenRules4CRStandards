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

(: Rule SD1045 - When IECAT = 'EXCLUSION' then IEORRES = 'Y' :)
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
(: get the IE dataset :)
for $iedataset in $definedoc//odm:ItemGroupDef[@Name="IE"]
let $iedatasetname := (
	if($defineversion = '2.1') then $iedataset/def21:leaf/@xlink:href
	else $iedataset/def:leaf/@xlink:href
)
let $iedatasetlocation := concat($base,$iedatasetname)
(: and get the OID of the IEORRES and IECAT variables :)
let $ieorresoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IEORRES']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
        return $a
)
let $iecatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='IECAT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the IE dataset :)
for $record in doc($iedatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values for IEORRES and IECAT :)
    let $ieorresvalue := $record/odm:ItemData[@ItemOID=$ieorresoid]/@Value
    let $iecatvalue := $record/odm:ItemData[@ItemOID=$iecatoid]/@Value
    (: When IECAT = 'EXCLUSION' then IEORRES = 'Y' :)
    where $iecatvalue='EXCLUSION' and not($ieorresvalue='Y')
    return <error rule="SD1045" variable="IEORRES" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}" dataset="IE">For IECAT='EXCLUSION', IEORRES must be 'Y' but {data($ieorresvalue)} was found</error>			

	