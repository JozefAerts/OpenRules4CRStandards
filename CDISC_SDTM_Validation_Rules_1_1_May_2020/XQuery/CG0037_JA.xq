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

(: Rule CG0037: For Events domains (except for DS, DV, HO) --BDSYCD = --SOCCD :)
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
(:  :)
let $definedoc := doc(concat($base,$define))
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS'  
	and not(@Domain='DS') and not(@Name='DS')
    and not(@Domain='DV') and not(@Name='DV')
    and not(@Domain='HO') and not(@Name='HO')]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: Get the OID of the --BDSYCD and --SOCCD variables, if any :)
    let $bdsycdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BDSYCD')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $bdsycdname := $definedoc//odm:ItemDef[@OID=$bdsycdoid]/@Name
    let $soccdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SOCCD')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $soccdname := $definedoc//odm:ItemDef[@OID=$soccdoid]/@Name
    (: iterate over all the records, at least if BDSYCD and SOCCD have been defined :)
    for $record in $datasetdoc//odm:ItemGroupData[$bdsycdoid and $soccdoid]
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the values of --BDSYCD and --SOCCD, when present :)
        let $bdsycdvalue := $record/odm:ItemData[@ItemOID=$bdsycdoid]/@Value
        let $soccdvalue := $record/odm:ItemData[@ItemOID=$soccdoid]/@Value
        (: when both present, they must be equal :)
        where $bdsycdvalue and $soccdvalue and $bdsycdvalue!=$soccdvalue
        return <error rule="CG0037" dataset="{data($name)}" variable="{data($bdsycdname)}" rulelastupdate="2020-06-09" recordnumber="{data($recnum)}">Value of {data($bdsycdname)} '{data($bdsycdvalue)}' and {data($soccdname)} '{data($soccdvalue)}' may not differ</error>	
	
	