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
	
(: Rule SD1083: Missing --DY variable, when --DTC variable is present:
Collection Study Day (--DY) variable should be included into dataset, when Collection Study Date/Time (--DTC) variable is present
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
(: iterate over all the datasets :)
for $dataset in $definedoc//odm:ItemGroupDef
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the --DY and --DTC variables  :)
    let $dyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DY') and string-length(@Name)=4]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dyname := $definedoc//odm:ItemDef[@OID=$dyoid]/@Name
    let $dtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DTC') and string-length(@Name)=5]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dtcname := $definedoc//odm:ItemDef[@OID=$dtcoid]/@Name
    (: this rule is about the presence in the dataset - not about whether the records are populated :)
    where not($dyoid) and $dtcoid
    return <warning rule="SD1083" rulelastupdate="2019-08-15">Collection Study Day {data(concat($name,'DY'))} variable must be included into dataset, when Collection Study Date/Time {data($dtcname)} variable is present in dataset {data($datasetname)}</warning>
