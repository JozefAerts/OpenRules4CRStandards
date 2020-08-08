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

(: Rule SD1241 When --BDSYCD != null then --BODSYS != null 
Applies to: AE, MH, CE :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Applies to: EVENTS,INTERVENTIONS :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Name='AE' or @Domain='AE' or @Name='MH' or @Domain='MH' or @Name='CE' or @Domain='CE']
    let $name := $itemgroupdef/@Name
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
	let $datasetlocation := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of --BDSYCD and of --BODSYS :)
    let $bdsycdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BDSYCD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $bdsycdname := $definedoc//odm:ItemDef[@OID=$bdsycdoid]/@Name
    let $bodsysoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BODSYS')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $bodsysname := $definedoc//odm:ItemDef[@OID=$bodsysoid]/@Name
    (: iterate over all the records that have --BDSYCD != null :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$bdsycdoid and @Value!='']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --BODSYS and of --BDSYCD :)
        let $bodsys := $record/odm:ItemData[@ItemOID=$bodsysoid]/@Value
        let $bdsycd := $record/odm:ItemData[@ItemOID=$bdsycdoid]/@Value
        (: --BODSYS must not be null :)
        where not($bodsys)
        return <error rule="SD1241" variable="{data($bdsycdname)}" dataset="{$name}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08">Null value found for {data($bodsysname)} where {data($bdsycdname)}='{data($bdsycd)}'</error>
       
	