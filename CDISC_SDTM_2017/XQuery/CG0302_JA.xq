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

(: Rule CG0302 - TRPORTOT not present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the TR dataset definitions, there should normally be only 1 :)
for $tritemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TR']
    (: get the OID of TRPORTOT, if any :)
    let $trportotoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TRPORTOT']/@OID
        where $a = $tritemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: TRPORTOT is not allowed to be present in TR. If it is, give an error :)
    where $trportotoid
    return <error rule="CG0302" dataset="TR" variable="TRPORTOT" rulelastupdate="2017-03-05">TRPORTOT is not allowed to be present in TR</error>			
		
		