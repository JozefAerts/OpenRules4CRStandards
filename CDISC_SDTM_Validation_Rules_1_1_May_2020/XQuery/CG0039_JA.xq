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

(: Rule CG0039: For Events domains (except for DS, DV, HO) --BODSYS = --SOC :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: iterate over Events datasets, except from DS, DV, HO :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' 
	or upper-case(./def21:Class/@Name)='INTERVENTIONS'
	and not(@Domain='DS') and not(@Name='DS')
    and not(@Domain='DV') and not(@Name='DV')
    and not(@Domain='HO') and not(@Name='HO')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: Get the OID of the --BDSYCD and --SOCCD variables, if any :)
    let $bodsysoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BODSYS')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $bodsysname := $definedoc//odm:ItemDef[@OID=$bodsysoid]/@Name
    let $socoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SOC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $socname := $definedoc//odm:ItemDef[@OID=$socoid]/@Name
    (: iterate over all the records, at least if BODSYS and SOC have been defined :)
    for $record in $datasetdoc//odm:ItemGroupData[$bodsysoid and $socoid]
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the values of --BODSYS and --SOC, when present :)
        let $bodsysvalue := $record/odm:ItemData[@ItemOID=$bodsysoid]/@Value
        let $socvalue := $record/odm:ItemData[@ItemOID=$socoid]/@Value
        (: when both present, they must be equal :)
        where $bodsysvalue and $socvalue and $bodsysvalue!=$socvalue
        return <error rule="CG0039" dataset="{data($name)}" variable="{data($bodsysname)}" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Value of {data($bodsysname)} '{data($bodsysvalue)}' and {data($socname)} '{data($socvalue)}' may not differ</error>	
	
	