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

(: Rule CG0127 - When ACTARMCD in ('SCRNFAIL', 'NOTASSGN')  then ACTARMCD = ARMCD :)
(: N/A for v3.3 (new variable ARMNRS) :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ARMCD and ACTARMCD :)
    let $armcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $actarmcdoid := (
       for $a in $definedoc//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all the records in the DM dataset that have ARMCD populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARMCD and ACTARMCD :)
        let $armcdvalue := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
        let $actarmcdvalue := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
        (: When ACTARMCD in ('SCRNFAIL', 'NOTASSGN')  then ACTARMCD = ARMCD :)
        where ($actarmcdvalue='SCRNFAIL' or $actarmcdvalue='NOTASSGN') and not($armcdvalue=$actarmcdvalue)
        return <error rule="CG0127" dataset="DM" variable="ACTARMCD" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Invalid value for ACTARMCD, value='{data($actarmcdvalue)}' is expected to be equal to the value of ARMCD='{data($armcdvalue)}'</error>			
		
	