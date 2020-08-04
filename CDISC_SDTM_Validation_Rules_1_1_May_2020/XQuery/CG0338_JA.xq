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

(: Rule CG0338 - --SCAT != --DECOD :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    (: we need the OID of --SCAT (if any) and the complete name :)
    let $scatoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SCAT') and string-length(@Name)=6]/@OID  (: to exclude --CAT :)
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $scatname := $definedoc//odm:ItemDef[@OID=$scatoid]/@Name
    (: and of --DECOD  :)
    let $decodoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DECOD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $decodname := $definedoc//odm:ItemDef[@OID=$decodoid]/@Name
    (: get the dataset location and document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: iterate over all records for which --CAT is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$scatoid] and odm:ItemData[@ItemOID=$decodoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --SCAT and of --DECOD :)
        let $scat := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        let $decod := $record/odm:ItemData[@ItemOID=$decodoid]/@Value
        (: the value of --SCAT may not be equal to the value of --DECOD:)
        where $scat=$decod
        return <error rule="CG0338" dataset="{data($name)}" variable="{data($scatname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of {data($scatname)}='{data($scat)}' is not allowed to be equal to the value of {data($decodname)}='{data($decod)}'</error>			
		
	