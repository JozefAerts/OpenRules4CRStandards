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

(: Rule CG0155: AP DOMAIN Value length = 4 characters beginning with 'AP' and ending with 2 character SDTM domain :)
(: TODO: check that 2 last characters correspond to an existing domain for the given SDTM-IG version. 
This will require the use of a RESTful web service :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the APxx dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'AP') and not(@Name='APRELSUB')]
    let $name := $itemgroupdef/@Name
    (: get the dataset location :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: we need the OID of DOMAIN :)
    let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the unique values of DOMAIN. This has the disadvantage however
    that the record number is lost :)
    let $uniquedomainvalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$domainoid]/@Value)
    for $domainvalue in $uniquedomainvalues
    (: value of DOMAIM must be 4 characters long and start with 'AP' :)
    (: we try to provide 3 different messages according to which part of the rule is violated :)
    (: ESSENTIALLY, this should not be 1 rule, but should be 3 different rules!  :)
    let $message := (
    	if(string-length($domainvalue) != 4) then 
          	<error rule="CG0155" dataset="{data($name)}" rulelastupdate="2020-06-14">Length of DOMAIN value '{data($domainvalue)}' is not 4</error> 
          else if(not(starts-with($domainvalue,'AP'))) then 
            <error rule="CG0155" dataset="{data($name)}" rulelastupdate="2020-06-14">DOMAIN value '{data($domainvalue)}' does not start with 'AP'</error> 
          else ()
	)
    return $message	
	
	