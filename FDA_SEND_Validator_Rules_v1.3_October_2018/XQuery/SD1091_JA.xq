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
	
(: Rule SD1091 - Missing --ENDY variable, when --ENDTC variable is present
Study Day of End (--ENDY) variable should be included into dataset, when End Study Date/Time (--ENDTC) variable is present
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
(: iterate over all SE, SV, INTERVENTIONS, EVENTS and FINDINGS datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='SV' or @Name='SE' or upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the ENTY and STDTC variable :)
    let $endyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDY')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a  
    )
    let $endyname := concat($name,'ENDY')   (: as in worst case, --SDTY may not be in dataset at all  :)
    let $endtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a  
    )
    let $endtcname := $definedoc//odm:ItemDef[@OID=$endtcoid]/@Name
    (: STDY variable must be present when STDTC is present :)
    where $endtcname and not($endyoid)
    return <error rule="SD1091" dataset="{data($name)}" variable="{data($endyname)}" rulelastupdate="2019-08-16">Missing {data($endyname)} variable in dataset {data($datasetname)}, when {data($endtcname)} variable is present</error>
