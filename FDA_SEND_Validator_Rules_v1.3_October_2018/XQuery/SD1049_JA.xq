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

(: Rule SD1049 - Invalid value for QLABEL:
 Qualifier Variable Label (QLABEL) value may have up to 40 characters :)
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
(: Get all the SUPPxx datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the QLABEL variable :)
    let $qlabeloid := (
        for $a in $definedoc//odm:ItemDef[@Name='QLABEL']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: Get the QLABEL value :)
    let $qlabelvalue := $record/odm:ItemData[@ItemOID=$qlabeloid]/@Value
    (: and check whether more than 40 characters :)
    where string-length($qlabelvalue) > 40
    return <error rule="SD1049" rulelastupdate="2019-09-03" dataset="{data($name)}" variable="QLABEL" recordnumber="{data($recnum)}">Invalid value for QLABEL in dataset {data($datasetname)} - Label={data($qlabelvalue)} has more than 40 characters</error>
