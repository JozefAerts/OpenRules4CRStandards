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

(: Rule SD1047 - Only one of Dose (--DOSE) or Dose Description (--DOSTXT) variables must be populated on the same record :)
(: corresponds to rule FDAC0155 :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets , but only the INTERVENTIONS ones :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='INTERVENTIONS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: get the OID of the --DOSE and --DOSTXT variables :)
    let $doseoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSE')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dosename := $definedoc//odm:ItemDef[@OID=$doseoid]/@Name
    let $dostxtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DOSTXT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dostxtname := $definedoc//odm:ItemDef[@OID=$dostxtoid]/@Name
    (: iterate over the records in the dataset, but ONLY when --DOSE and --DOSTXT were defined :)
    for $record in$datasetdoc[$doseoid and $dostxtoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of --DOSE and --DOSTXT (when present) :)
        let $dosevalue := $record/odm:ItemData[@ItemOID=$doseoid]/@Value
        let $dostxtvalue := $record/odm:ItemData[@ItemOID=$dostxtoid]/@Value
        (: When --DOSTXT != null then --DOSE = null :)
        where $dostxtvalue and $dosevalue (: --DOSTXT is populated and --DOSE is populated :)
        return <error rule="SD1047" dataset="{data($name)}" variable="{data($dosename)}" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">Both {data($dosename)} and {data($dostxtname)} are populated</error>			
		
	