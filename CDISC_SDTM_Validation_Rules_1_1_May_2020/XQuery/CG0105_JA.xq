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

(: Rule CG0105 - when EC domain is present then EXVAMT not present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the EC dataset/domain(s) definition - just for presence... :)
let $ecdomain := $definedoc//odm:ItemGroupDef[@Domain='EC' or starts-with(@Name,'EC')]
(: get the EX dataset(s) definition :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Domain='EX' or starts-with(@Name,'EX')]
    let $name := $itemgroupdef/@Name
    (: get the OID of EXVAMT :)
    let $exvamtoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EXVAMT']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    where $ecdomain and $exvamtoid  (: EC domain is present and EXVAMT is present :)
    return 
        <error rule="CG0105" dataset="{data($name)}" variable="EXVAMT" rulelastupdate="2020-06-14">EXVAMT is present in dataset although the EC domain/dataset is present</error>
         
	