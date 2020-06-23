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

(: Rule CG0568: EXMETHOD not present in dataset :)
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
(: iterate over all EX datasets, usually there is only 1 however :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='EX' or @Domain='EX']
	let $name := $itemgroupdef/@Name
    (: get the EXMETHOD variable (when present) :)
    let $exmethodoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EXMETHOD']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: EXMETHOD is not allowed to be present, so give an error when it is present :)
    where $exmethodoid
    return <error rule="CG0568" dataset="{data($name)}" rulelastupdate="2020-06-22">Variable EXMETHOD is not allowed to be used in dataset {data($name)}</error>				
	
	