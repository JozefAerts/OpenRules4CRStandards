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

(: Rule CG0320 - When Findings custom domain present in study then --TESTCD present in dataset :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get a list of all Findings domains defined by SDTM for IG version 3.2 :)
let $standarddomains := doc('http://xml4pharmaserver.com:8080/CDISCDomainService/rest/DomainForClassForVersion/SDTM/Findings/3.2')/XML4PharmaServerWebServiceResponse/WebServiceResponse/domain/@name
(: iterate over all the dataset definitions for datasets that are FINDINGS datasets but are NOT standard domains :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' and not(functx:is-value-in-sequence(@Name,$standarddomains))]
    let $name := $itemgroupdef/@Name
    (: get the OID of the --TESTCD variable (if any) :)
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: If no --TESTCD is present, give an error :)
    where not($testcdoid)
    return <error rule="CG0320" dataset="{data($name)}" rulelastupdate="2017-03-07">No --TESTCD variable is present in custom Findings domain dataset {data($name)}</error>			
		
		