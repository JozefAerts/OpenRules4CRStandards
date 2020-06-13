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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Applies to: all datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2) (: first 2 characters :)
    )
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    (: get the OID and name of --RFTDTC :)
    let $rftdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'RFTDTC')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $rftdtcname := $definedoc//odm:ItemDef[@OID=$rftdtcoid]/@Name
    (: get the OID of --TPTREF (if any) :)
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name
    (: get the dataset location and document :)
    let $datasetname := $itemgroupdef/def:leaf/@xlink:href
   	let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: iterate over all rows in the dataset, 
    but only when there --RFTDTC and --TPTREF have been defined :)
    for $record in $datasetdoc//odm:ItemGroupData[$rftdtcoid and $tptrefoid]
    	let $recnum := $record/@data:ItemGroupDataSeq
    	(: get the values of --RFTDTC and --TPTREF :)
        let $rftdtcvalue := $record/odm:ItemData[@ItemOID=rftdtcoid]/@Value
        let $tptrefvalue := $record/odm:ItemData[@ItemOID=tptrefoid]/@Value
    	(: When --TPTREF = null then --RFTDTC = null :)
        (: Give an error when TPTREF is null but RFTDTC has a value :)
        where not($tptrefvalue) and $rftdtcvalue 
        return <error rule="CG0026" dataset="{data($name)}" variable="{data($rftdtcname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-06-08">Value for {data($rftdtcname)} is '{data($rftdtcvalue)}' although value for {data($tptrefname)} is null</error>
        
	