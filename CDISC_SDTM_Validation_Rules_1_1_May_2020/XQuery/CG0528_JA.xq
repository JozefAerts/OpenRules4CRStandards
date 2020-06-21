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

(: Rule CG0528: DM/SUPPDM: "ADSL Population flags (COMPLT; FULLSET; ITT; PPROT; and SAFETY) not in SUPPDM":)
xquery version "3.0";
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
(: Get the SUPPDM dataset - there should be only one :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='SUPPDM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: and the document for it (when present) :)
    let $suppdmdoc := (
    	if($datasetname) then doc($datasetlocation)
        else ()
    )
    (: get the OID of QNAM :)
    let $qnamoid := (
        for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPDM']/odm:ItemRef/@ItemOID
        return $a
    )
	(: iterate over all the records in the SUPPDM dataset :)
    for $record in $suppdmdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of QNAM :)
        let $qnamvalue := $record/odm:ItemData[@ItemOID=$qnamoid]/@Value
        (: give an error when the value of QNAM is one of 'COMPLT', 'FULLSET', 'ITT', 'PPROT', or 'SAFETY' :)
        where starts-with($qnamvalue,'COMPLT') or starts-with($qnamvalue,'FULLSET') or starts-with($qnamvalue,'ITT') or starts-with($qnamvalue,'PPROT') or starts-with($qnamvalue,'SAFETY')
        return <error rule="CG0528" dataset="SUPPDM" variable="QNAM" rulelastupdate="2020-06-21" recordnumber="{data($recnum)}">Supplemental qualifier '{data($qnamvalue)}' is not allowed to be used in SUPPDM</error>	
	
	