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

(: Rule CG0561: When PEORRES = null, then PESTRESC = null
Single dataset version :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the PE datasets - there should be only 1 :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='PE']
	(: get the OIDs of PEORRES and PESTRESC :)
    let $peorresoid := (
        for $a in $definedoc//odm:ItemDef[@Name='PEORRES']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
   	let $pestrescoid := (
        for $a in $definedoc//odm:ItemDef[@Name='PESTRESC']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and document :)
    let $pedatasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $pedoc := (
    	if($pedatasetlocation) then doc(concat($base,$pedatasetlocation))
        else ()
    )
    (: iterate over all records that have PEORRES=null :)
    for $record in $pedoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$peorresoid])]
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: and give an error when PESTRESC is populated :)
        let $pestrescvalue := $record/odm:ItemData[@ItemOID=$pestrescoid]/@Value
        where $pestrescvalue 
    	return <error rule="CG0561" dataset="PE" rulelastupdate="2020-06-22">PEORRES is null, but PESTRESC is not null: '{data($pestrescvalue)}' was found</error> 	
	
	