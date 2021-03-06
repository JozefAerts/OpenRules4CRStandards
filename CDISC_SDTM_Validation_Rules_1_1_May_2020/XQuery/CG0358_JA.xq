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

(: Rule CG0358 - SBSTRAIN not present in DM dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the DM dataset :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
    (: and get the OID of the SBSTRAIN variable (if any) :)
    let $sbstrainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='SBSTRAIN']/@OID 
        where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: SBSTRAIN is not allowed to be present :)
    where $sbstrainoid
    return <error rule="CG0358" dataset="DM" variable="SBSTRAIN" rulelastupdate="2020-08-04">The use of the variable 'SBSTRAIN' is not allowed in SDTM domain 'DM' (it is specific to SEND)</error>			
		
	