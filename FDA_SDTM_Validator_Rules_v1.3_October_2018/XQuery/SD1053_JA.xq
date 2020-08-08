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
(: get the OID of the ARMCD variable in the define.xml for TA and TV :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TA' or @Name='TV']
    let $itemgroupdefname := $itemgroupdef/@Name
    (: get the OID of ARMCD :)
    let $armcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    ) 
    (: and the location of the dataset :)
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    (: iterate over all ARMCD record in the dataset :)
    for $record in doc($dataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$armcdoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $armcdvalue := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
        (: ARMCD is not allowed to be SCRNFAIL nor NOTASSGN :)
        where $armcdvalue = 'SCRNFAIL' or $armcdvalue = 'NOTASSGN'
        return <error rule="SD1053" dataset="{data($itemgroupdefname)}" variable="ARMCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Unexpected value for ARMCD={data($armcdvalue)} in dataset {data($itemgroupdefname)} - 'SCRNFAIL' and 'NOTASSGN' are not allowed to appear in TA nor TV</error>
