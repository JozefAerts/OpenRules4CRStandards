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

(: Rule CG0547: SMSTDTC ^= null :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";

(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over SM datasets - there should be only 1 though:)
for $smitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='SM']
	let $name := $smitemgroupdef/@Name
    (: We need the OIDs of SMSTDTC :)
    let $smstdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name='SMSTDTC']/@OID 
        where $a = $smitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
   (: get the SM dataset location and the document itself :)
    let $smdatasetlocation := $smitemgroupdef/def:leaf/@xlink:href
    let $smdoc := (
    	if($smdatasetlocation) then doc(concat($base,$smdatasetlocation))
        else ()
    )
    (: iterate over all SM records  :)
    for $record in $smdoc//odm:ItemGroupData
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of MSSTDTC :)
        let $msstdtcvalue := $record/odm:ItemData[@ItemOID=$smstdtcoid]/@Value
        (: give an error when MSSTDTC is not populated :)
        where not($msstdtcvalue)
        return <error rule="CG0547" dataset="{data($name)}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-22">Value for MSSTDTC is missing</error>	
	
	