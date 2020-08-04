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

(: Rule CG 0040: AEOCCUR may not be present in AE :)
(: Explanation from SDTM-IG: AEOCCUR is not permitted because the AE domain contains only records for adverse events that actually occurred. :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: As when using Dataset-XML, the variable name is not in the dataset itself (the OID is) we need to check in the define.xml :)
(: find the AEOCCUR variable in the define.xml :)
let $aeoccur := (
    for $a in $definedoc//odm:ItemDef[@Name='AEOCCUR']/@OID 
        (: keep 'splitted' AE datasets into account :)
        where $a = $definedoc//odm:ItemGroupDef[@Name='AE' or @Domain='AE']/odm:ItemRef/@ItemOID
        return $a 
    )
    (: Give an error when AEOCCUR exists :)
    where $aeoccur
    return 
     <error rule="CG0040" rulelastupdate="2020-08-04" dataset="AE" variable="AEOCCUR">AEOCCUR is not allowed in AE because the AE domain contains only records for adverse events that actually occurred</error>			
