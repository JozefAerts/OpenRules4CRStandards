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

(: Rule CG0541: --LOBXFL Value must be 'Y' or null :)
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
(: iterate over the FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
	let $name := $itemgroupdef/@Name
    (: get the OID of the --LOBXFL variable  :)
    let $lobxfloid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'LOBXFL')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the name of the --LOBXFL variable :)
    let $lobxflname := $definedoc//odm:ItemDef[@OID=$lobxfloid]/@Name
    (: get the location of the dataset and the document itself :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset, when --LOBXFL is present :)
    for $record in $datasetdoc[$lobxfloid]//odm:ItemGroupData
    	let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the value of the --LOBXFL variable :)
        let $lobxflvalue := $record/odm:ItemData[@ItemOID=$lobxfloid]/@Value
        (: the value must be either null or 'Y' :)
        (: where $lobxflvalue and $lobxflvalue != 'Y' :)
        return <error rule="CG0541" dataset="{data($name)}" recordnumber="{data($recnum)}" variable="{data($lobxflname)}" rulelastupdate="2020-06-22">Value of {data($lobxflname)} is not null or 'Y' - value {data($lobxflvalue)}</error>	
	
	