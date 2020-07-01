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

(: Rule SD0035 - When --DOSE != null or --DOSTOT != null or --DOSTXT != null then --DOSU != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets , but only the INTERVENTIONS ones :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS']
    (: get the dataset :)
    let $domain := $dataset/@Domain
    let $name := $dataset/@Name
    (: the prefix (first 2 characters) is either the domain name or the first characters of the dataset name (case splitted domains) :)
    let $prefix := (
        if($dataset/@Domain) then $dataset/@Domain
        else substring($name,1,2)
    )
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetname))
    (: get the OID and name of the --DOSTOT variable :)
    let $dostotoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSTOT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dostotname := concat($prefix,'DOSTOT')
    (: get the OID and name of the --DOSE variable :)
    let $doseoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSE')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dosename := concat($prefix,'DOSE')
    (: get the OID and name of the --DOSTXT variable :)
    let $dostxtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSTXT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dostxtname := concat($prefix,'DOSTXT')
    (: get the OID and name of the DOSU variable :)
    let $dosuoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSU')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dosuname := doc(concat($base,$define))//odm:ItemDef[@OID=$dosuoid]/@Name
    (: iterate over all record in the dataset for which there is a DOSE, DOSTXT or DOSTOT data point :) 
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$doseoid] or odm:ItemData[@ItemOID=$dostxtoid] or odm:ItemData[@ItemOID=$dostotoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: DOSEU must be populated :)
        where not($record/odm:ItemData[@ItemOID=$dosuoid])
        return <error rule="SD0035" dataset="{data($name)}" variable="{data($dosuname)}" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">{data($dosuname)} is not populated although one of {data($dosename)}, {data($dostxtname)} or {data($dostotname)} is populated</error>				
		
	