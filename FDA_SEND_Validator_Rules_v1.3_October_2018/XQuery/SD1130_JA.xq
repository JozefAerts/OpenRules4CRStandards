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
		
(: Rule SD1130 - Inconsistent value for QNAM within QLABEL
All values of Qualifier Variable Name (QNAM) should be the same for a given value of Qualifier Variable Label (QLABEL)
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
(: Iterate over all SUPPxx datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and get the OID of QLABEL and of QNAM :)
    let $qlabeloid := (
        for $a in $definedoc//odm:ItemDef[@Name='QLABEL']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $qnamoid := (
        for $a in $definedoc//odm:ItemDef[@Name='QNAM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: get all unique QLABEL values within the dataset :)
    let $uniqueqlabelvalues := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$qlabeloid]/@Value)
        (: iterate over these unique QLABEL values and for each of them, 
        find all records - also all with the same value for QLABEL :)
        for $uniqueqlabel in $uniqueqlabelvalues
            let $records := $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$qlabeloid][@Value=$uniqueqlabel]]
            (: now get the distinct values for QNAM within each QLABEL :)
            let $uniqueqnamvalues := distinct-values($records/odm:ItemData[@ItemOID=$qnamoid]/@Value)
            (: the number of unique QNAM values for each QLABEL must be 1 :)
            let $uniqueqnamvaluescount := count($uniqueqnamvalues)
            where $uniqueqnamvaluescount != 1
            return <warning rule="SD1130" dataset="{data($name)}" variable="QNAM" rulelastupdate="2019-08-14">Inconsistent value for QNAM within QLABEL={data($uniqueqlabel)} in dataset {data($datasetname)}. {data($uniqueqnamvaluescount)} different combinations were found</warning>			
