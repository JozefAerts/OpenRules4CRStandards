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

(: Rule CG0131 - DTHFL in ('Y',null) :)
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
(: Get the DM dataset - we use a "for" although there can only be one :)
for $dmitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='DM']
	let $datasetname := (
		if($defineversion='2.1') then $dmitemgroupdef/def21:leaf/@xlink:href
		else $dmitemgroupdef/def:leaf/@xlink:href
	)
    let $dmdatasetlocation := concat($base,$datasetname)
    let $dmdatasetdoc := doc($dmdatasetlocation)
    (: get the OID of DTHFL in DM :)
    let $dthfloid := (
        for $a in $definedoc//odm:ItemDef[@Name='DTHFL']/@OID 
        where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the DM dataset for which there IS a value for DTHFL :)
    for $record in $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dthfloid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of DTHFL :)
        let $dthflvalue := $record/odm:ItemData[@ItemOID=$dthfloid]/@Value
        (: as we iterate over all records in the DM dataset for which there IS a value for DTHFL, 
        we only need to check whether the value is 'Y' :)
        where not($dthflvalue='Y')
             return <error rule="CG0131" dataset="DM" variable="DTHFL" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Invalid value for DTHFL, value='{data($dthflvalue)}' is expected to be 'Y' or null</error>			
		
	