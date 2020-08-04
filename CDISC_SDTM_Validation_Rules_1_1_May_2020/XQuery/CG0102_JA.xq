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

(: When EXTRT = 'PLACEBO' then EXDOSE = 0 :)
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
(: get the EX dataset(s) definition :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Domain='EX' or starts-with(@Name,'EX')]
    let $name := $itemgroupdef/@Name
    (: get the dataset itself :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of EXTRT and EXDOSE :)
    let $extrtoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EXTRT']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (:  :)
    let $exdoseoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EXDOSE']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: return <test>{data($extrtoid)}</test>		 :)
    (: get all the records in the dataset for which EXTRT='PLACEBO' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$extrtoid and @Value='PLACEBO']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of EXDOSE (as text) :)
        let $exdose := $record/odm:ItemData[@ItemOID=$exdoseoid]/@Value
        (: When EXTRT = 'PLACEBO' then EXDOSE = 0 :)
        where $exdose castable as xs:double and xs:double($exdose)!= 0 
        return 
			<error rule="CG0102" dataset="{data($name)}" variable="EXDOSE" rulelastupdate="2020-08-04" recordnumber="{$recnum}">EXDOSE={data($exdose)} is expected to be 0 as EXTRT='PLACEBO'</error>	
		
	