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
	
(: No --BLFL variable in custom Findings domain :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: In this implementation, we trust that a custom domain name starts with X, Y or Z
 as define.xml 2.0 does not have a notion of "custom domain" yet - this comes first with define.xml 2.1 :)
for $datasetdef in doc(concat($base,$define))//odm:ItemGroupDef[starts-with(@Name,'X') or starts-with(@Name,'Y') or starts-with(@Name,'Z')][upper-case(@def:Class) = 'FINDINGS']
    let $name := $datasetdef/@Name
    let $blflname := concat($name,'BLFL')
    (: get the definition of --BLFL (if any) :)
    let $blfloid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'BLFL')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    where not($blfloid)
    return <warning rule="SD1044" dataset="{data($name)}" variable="{data($blflname)}" rulelastupdate="2019-08-15">No baseline variable {data($blflname)} in custom Findings dataset {data(name)}</warning>	 

