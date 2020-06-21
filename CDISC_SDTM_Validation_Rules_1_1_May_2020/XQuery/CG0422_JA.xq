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

xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all FINDINGS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $itemgroupdef/@Name
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the --STAT and --ORRES variable :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := $definedoc//odm:ItemDef[@OID=$statoid]/@Name
    let $orresoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORRES')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $orresname := doc(concat($base,$define))//odm:ItemDef[@OID=$orresoid]/@Name
    (: iterate over all records for which ORRES is populated - but only when --STAT was at least defined :)
    for $record in $datasetdoc[$orresoid and $statoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$orresoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STAT and of --ORRES :)
        let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        let $orresvalue := $record/odm:ItemData[@ItemOID=$orresoid]/@Value
        (: STAT must be null :)
        where $statvalue
        return <error rule="CG0422" dataset="{data($name)}" variable="{data($statname)}" rulelastupdate="2020-06-19" recordnumber="{data($recnum)}">{data($statname)} must be NULL, as ({data($orresname)})='{data($orresvalue)}' is not null. {data($statname)}='{data($statvalue)}' is found</error>
			
	