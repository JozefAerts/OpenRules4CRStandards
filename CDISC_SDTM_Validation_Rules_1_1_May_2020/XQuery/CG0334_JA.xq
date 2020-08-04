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

(: Rule CG0334 - When Dataset name begins with 'SUPP' then value of RDOMAIN equals characters 5 and 6 of the dataset name :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: Iterate over all SUPPxx datasets :)
for $suppitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $suppitemgroupdef/@Name
    (: get the 5th and 6th character of SUPPxx :)
    let $refdomain := substring($name,5,2)
    (: we need the OID of the RDOMAIN variable :)
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID
        where $a = $suppitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location and the document itself :)
	let $suppdatasetlocation := (
		if($defineversion='2.1') then $suppitemgroupdef/def21:leaf/@xlink:href
		else $suppitemgroupdef/def:leaf/@xlink:href
	)
    let $suppdatasetdoc := (
		if($suppdatasetlocation) then doc(concat($base,$suppdatasetlocation))
		else ()
	)
    (: iterate over all records in the current SUPPxx dataset :)
    for $record in $suppdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rdomainoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of RDOMAIN :)
        let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        (: the value must be equal to the 5th and 6th character of the dataset name :)
        where not($rdomain=$refdomain)
        return <error rule="CG0334" dataset="{data($name)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of RDOMAIN='{data($rdomain)}' does not correspond to the 5th and 6th character of the dataset name '{data($name)}'</error>						
		
	