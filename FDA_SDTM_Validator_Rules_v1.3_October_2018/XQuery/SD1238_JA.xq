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

(: Rule : SD1238: --RFTDTC is populated when --TPTREF is not populated - 
 Applies to all datasets :)
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
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: iterate over the dataset definitions :)
for $datasetdef in $definedoc//odm:ItemGroupDef
    (: get the name of the dataset :)
    let $name := $datasetdef/@Name
    (: get the OIDs of the --RFTDTC and --TPTREF variables :)
    let $rftdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'RFTDTC')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $rftdtcdname := $definedoc//odm:ItemDef[@OID=$rftdtcoid]/@Name
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name
    (: get the location of the dataset :)
    let $datasetlocation := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the dataset document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset, at least when TESTCD and TEST have been defined for the dataset :)
    for $record in $datasetdoc[$rftdtcoid and $tptrefoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of --RFTDTC and of --TPTREF :)
        let $tptrefvalue := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value
        let $rftdtcvalue := $record/odm:ItemData[@ItemOID=$rftdtcoid]/@Value
        (: when RFTDTC is populated, also TPTREF must be populated :)
        where $rftdtcvalue != '' and not($tptrefvalue) 
        return <error rule="SD1238" dataset="{data($name)}" variable="{$tptrefname}" rulelastupdate="2020-08-08">{data($rftdtcdname)} is populated but {$tptrefname} is not populated</error>		

