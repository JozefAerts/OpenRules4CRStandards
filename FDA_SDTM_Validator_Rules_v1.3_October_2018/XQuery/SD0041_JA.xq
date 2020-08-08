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

(: Rule SD0041: Occurrence (--OCCUR) may only be populated, when a given Intervention or Event has been pre-specified (--PRESP = 'Y')
 Applies to: INTERVENTIONS, EVENTS :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the EVENTS and INTERVENTIONS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS']
    let $name := $itemgroupdef/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OID of --OCCUR and of --PRESP :)
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[@OID=$occuroid]/@Name
    let $prespoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'PRESP')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $prespname := $definedoc//odm:ItemDef[@OID=$prespoid]/@Name
    (: iterate over all records for which --PRESP is NOT 'Y' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$prespoid and not(@Value='Y')] or not(odm:ItemData[@ItemOID=$prespoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --OCCUR - if any:)
        let $occur := $record/odm:ItemData[@ItemOID=$occuroid]/@Value
        (: occur must be empty or null :)
        where string-length($occur) > 0
        return <error rule="SD0041" rulelastupdate="2020-08-08" dataset="{data($name)}" variable="{data($occurname)}" recordnumber="{data($recnum)}">{data($occurname)} is populated, value={data($occur)} although {data($prespname)} is not populated or absent</error>		
	
	