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

(: Rule CG0463 - INTERVENTIONS class: When custom domain present in study then --TRT present in dataset:)
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
(: the INTERVENTIONS domains 
Alternative: use the RESTful web service: 
http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/INTERVENTIONS/3.2 :)
let $interventiondomains := ('CM','EC','EX','PR','SU')
(: iterate over all custom domains in the submission that are INTERVENTIONS domains 
so that are not in the list of the SDTM intervention domains :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' and not(functx:is-value-in-sequence(substring(@Name,1,2),$interventiondomains))]
    let $name := $itemgroupdef/@Name
    (: assert that there is a --TRT variable defined in this dataset :)
    let $trtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TRT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $varname := concat($name,'TRT')
    (: --TRT must be defined :)
    where not($trtoid)
    return <error rule="CG0463" dataset="{data($name)}" variable="{data($varname)}" rulelastupdate="2017-03-25">{data($varname)} is not present in FINDINGS custom domain {data($name)}</error>										
		
	