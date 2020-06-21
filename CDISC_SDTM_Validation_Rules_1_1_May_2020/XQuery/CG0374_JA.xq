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
	
(: Rule CG0374 - When RELREC dataset present in study then dataset present in study with DOMAIN = RELREC.RDOMAIN :)
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
(: Get the RELREC dataset :)
let $itemgroupdef := $definedoc//odm:ItemGroupDef[@Name='RELREC']
(: Get the location :)
let $datasetname := $itemgroupdef/def:leaf/@xlink:href
let $datasetlocation := concat($base,$datasetname)
let $datasetdoc := doc($datasetlocation)
(: get the OID of RDOMAIN :)
let $rdomainoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
    where $a = $itemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the distinct values of RDOMAIN in the RELREC dataset - there will probably be more than one :)
let $domainvalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$rdomainoid]/@Value)
(: iterate over them :)
for $rdomain in $domainvalues
    (: there must be at least one dataset for the referenced domain :)
    let $count := count($definedoc//odm:ItemGroupDef[@Domain=$rdomain or substring(@Name,1,2)=$rdomain])
    (: if no such dataset was found, give an error :)
    where $count = 0
    return <error rule="CG0374" dataset="RELREC" rulelastupdate="2020-06-18">No parent dataset/domain was found for RDOMAIN='{data($rdomain)}'</error>		
		
	