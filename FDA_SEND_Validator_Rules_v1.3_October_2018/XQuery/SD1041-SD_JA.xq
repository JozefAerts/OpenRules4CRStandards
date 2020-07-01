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

(: Rule : SD1041: Values for --CAT and --SCAT are identical - 
 Applies to INTERVENTIONS, EVENTS, FINDINGS, TI :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: iterate over the dataset definitions in INTERVENTIONS, EVENTS, FINDINGS, TI :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Domain='TI']
    (: get the name of the dataset :)
    let $name := $datasetdef/@Name
    (: get the OIDs of the --CAT and --SCAT variables :)
    let $catoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'CAT') and string-length(@Name)=5]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $catname := $definedoc//odm:ItemDef[@OID=$catoid]/@Name
    let $scatoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'SCAT') and string-length(@Name)=6]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $scatname := $definedoc//odm:ItemDef[@OID=$scatoid]/@Name
    (: get the location of the dataset :)
    let $datasetlocation := $datasetdef/def:leaf/@xlink:href
    (: and the dataset document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset, at least when --CAT and --SCAT have been defined for the dataset :)
    for $record in $datasetdoc[$catoid and $scatoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of --CAT and of --SCAT :)
        let $catvalue := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        let $scatvalue := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        (: SCAT and CAT may not be identical :)
        where $catvalue = $scatvalue
        return <error rule="SD1041" dataset="{data($name)}" variable="{$scatname}" rulelastupdate="2019-08-20">{data($scatname)} value '{data($catvalue)}' is identical to {data($catname)} value '{data($scatvalue)}'</error>		

