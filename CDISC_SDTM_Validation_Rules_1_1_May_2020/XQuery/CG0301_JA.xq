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

(: Rule CG0301 - TRDIR not present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the TR dataset definitions, there should normally be only 1 :)
for $tritemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TR']
    (: get the OID of TRDIR, if any :)
    let $trdiroid := (
        for $a in $definedoc//odm:ItemDef[@Name='TRDIR']/@OID
        where $a = $tritemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: TRDIR is not allowed to be present in TR. If it is, give an error :)
    where $trdiroid
    return <error rule="CG0301" dataset="TR" variable="TRDIR" rulelastupdate="2020-08-04">TRDIR is not allowed to be present in TR</error>						
		
	