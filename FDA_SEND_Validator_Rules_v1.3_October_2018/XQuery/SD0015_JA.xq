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
	
(: Rule SD0015 - Negative value for --DUR (all domains)
Non-missing Duration of Event, Exposure or Observation (--DUR) value must be greater than or equal to 0
:)
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
(: iterate over all datasets that have a --DOSE variable :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Name='TE' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'
		or @Name='TV' or @Name='SV'] 
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: find the OID of the --DOSE variable :)
    let $duroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DUR') or @Name='AGE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $durname := $definedoc//odm:ItemDef[@OID=$duroid]/@Name
    (: now iterate over all in the dataset itself :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value :)
        let $durvalue := $record/odm:ItemData[@ItemOID=$duroid]/@Value
        (: and check whether >= 0 :)
        where $durvalue and starts-with($durvalue,'-') (: a --DUR value is present and it is a -P so negative value :)
        return <error rule="SD0015" dataset="{data($name)}" variable="data{data($durname)}" rulelastupdate="2019-08-18" recordnumber="{data($recnum)}">Negative value for {data($durname)} in dataset {data($datasetname)}: {data($durvalue)} was found</error>	
