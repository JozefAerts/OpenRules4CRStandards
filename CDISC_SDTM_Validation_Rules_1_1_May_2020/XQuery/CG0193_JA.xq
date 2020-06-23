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

(: Rule CG0193 - When MBTESTCD = 'ORGANISM' and MBSTRESC ^= 'NO GROWTH' and MBMETHOD ^= 'GRAM STAIN', then MBRESCAT != null :)
(: Not applicable to SDTMIG v.3.3, as test code terminology expectations have changed :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the MB dataset and its location :)
let $mbitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='MB']
let $mbdatasetlocation := $mbitemgroupdef/def:leaf/@xlink:href
let $mbdatasetdoc := doc(concat($base,$mbdatasetlocation))
(: get the OID of MBTESTCD and of MBRESCAT :)
let $mbtestcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBTESTCD']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $mbrescatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBRESCAT']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: We also need the OIDs of MBSTRESC and MBMETHOD :)
let $mbstrescoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBSTRESC']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $mbmethodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MBMETHOD']/@OID 
        where $a = $mbitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records for which MBTESTCD='ORGANISM', 
	and MBSTRESC != 'NO GROWTH' and MBMETHOD != 'GRAM STAIN'	:)
for $record in $mbdatasetdoc[$mbtestcdoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$mbtestcdoid and @Value='ORGANISM'] 
		and odm:ItemData[@ItemOID=$mbstrescoid and @Value!='NO GROWTH']
        and odm:ItemData[@ItemOID=$mbmethodoid and @Value!='GRAM STAIN']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of MBRESCAT (if any) :)
    let $mbrescat := $record/odm:ItemData[@ItemOID=$mbrescatoid]/@Value
    (: Then MBRESCAT != null :)
    where not($mbrescat)  (: meaning MBRESCAT=absent/null :)
    return <error rule="CG0193" dataset="MB" variable="MBRESCAT" rulelastupdate="2020-06-14" recordnumber="{data($recnum)}">MBTESTCD='ORGANISM' and MBSTRESC!='NO GROWTH' and MBMETHOD!='GRAM STAIN' but MBRESCAT=null</error>	
     
	