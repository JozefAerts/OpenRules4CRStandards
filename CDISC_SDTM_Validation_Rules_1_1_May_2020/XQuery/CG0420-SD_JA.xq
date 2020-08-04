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

(: Rule CG0420 - When --OCCUR = 'N' then --STRF = null :)
xquery version "3.0";
declare namespace def="http://www.cdisc.org/ns/def/v2.0";
declare namespace def21="http://www.cdisc.org/ns/def/v2.1";
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
(: iterate over all the provided datasets within INTERVENTIONS and EVENTS dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS']
    let $name := $itemgroupdef/@Name
    (: get the OID of --OCCUR and of --STRF (if any) :)
    let $strfoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRF')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $strfname := $definedoc//odm:ItemDef[@OID=$strfoid]/Name
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $occurname := $definedoc//odm:ItemDef[@OID=$occuroid]/@Name
    (: get the location of the dataset and the document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all the records in the dataset, but ONLY when --OCCUR and --STRF have been defined,
    and only those for which --OCCUR='N'  :)
    for $record in $datasetdoc[$occuroid and $strfoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$occuroid and @Value='N']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --STRF (if any) :)
        let $strf := $record/odm:ItemData[@ItemOID=$strfoid]/@Value
        (: --STRF must be null :)
        where $strf and string-length($strf)>0
        return <error rule="CG0420" dataset="{data($name)}" variable="{data($strfname)}" rulelastupdate="2020-08-04" recordnumer="{data($recnum)}">{data($occurname)}='N' but {data($strfname)} is not null. {data($strfname)}='{data($strf)}' is found</error>				
		
	