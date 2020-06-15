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

(: Rule CG0176 - When IECAT = 'INCLUSION' then IEORRES = 'N' :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the IE dataset :)
let $iedataset := $definedoc//odm:ItemGroupDef[@Name="IE"]
let $iedatasetlocation := $iedataset/def:leaf/@xlink:href
let $iedatasetdoc := (
	if ($iedatasetlocation) then 
		doc(concat($base,$iedatasetlocation))
    else ()
)
(: and get the OID of the IEORRES and IECAT variables :)
let $ieorresoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='IEORRES']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
        return $a
)
let $iecatoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='IECAT']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='IE']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the IE dataset when there is one :)
for $record in $iedatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values for IEORRES and IECAT :)
    let $ieorresvalue := $record/odm:ItemData[@ItemOID=$ieorresoid]/@Value
    let $iecatvalue := $record/odm:ItemData[@ItemOID=$iecatoid]/@Value
    (: When IECAT = 'INCLUSION' then IEORRES = 'N' :)
    where $iecatvalue='INCLUSION' and not($ieorresvalue='N')
	return <error rule="CG0176" rulelastupdate="2020-06-14" recordnumber="{data($recnum)}" dataset="IE" variable="IEORRES">For IECAT='INCLUSION', IEORRES must be 'N' but {data($ieorresvalue)} was found</error>			
	
	