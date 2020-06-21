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

(: Rule CG0464 - EVENTS class: When Custom domain present in study then --TERM present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: the EVENTS domains 
Alternative: use the RESTful web service: 
http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/EVENTS/3.2 :)
let $eventsdomains := ('AE','CE','DS','DV','HO','MH')
(: iterate over all custom domains in the submission that are EVENTS domains 
so that are not in the list of the SDTM events domains :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='EVENTS' and not(functx:is-value-in-sequence(substring(@Name,1,2),$eventsdomains))]
    let $name := $itemgroupdef/@Name
    (: assert that there is a --TERM variable defined in this dataset :)
    let $termoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TERM') and string-length(@Name)=6]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $varname := concat($name,'TERM')
    (: --TERM must be defined :)
    where not($termoid)
    return <error rule="CG0464" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2020-06-19">{data($varname)} is not present in EVENTS custom domain {data($name)}</error>										
		
	