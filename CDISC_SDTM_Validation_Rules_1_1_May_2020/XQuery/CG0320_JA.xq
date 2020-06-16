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
(: Iterate over all datasets that are defined as "Findings" in the define.xml  :)
for $findingsitemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
	let $name := $findingsitemgroupdef/@Name
    (: Get the OID of any "--TESTCDC" (when present) :)
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD') and string-length(@Name)=8]/@OID
        where $a = $findingsitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: Give an error when no --TESTCD variable was found  :)
    where not($testcdoid)
    return <error rule="CG0320" dataset="{data($name)}" rulelastupdate="2020-06-15">No --TESTCD variable is present in custom Findings domain dataset {data($name)}</error>			
		
	