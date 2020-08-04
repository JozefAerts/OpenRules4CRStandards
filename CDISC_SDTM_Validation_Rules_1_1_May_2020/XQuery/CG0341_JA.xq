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

(: Rule CG0341 - --TESTCD != 'OTHER' :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS']
    let $name := $itemgroupdef/@Name
    (: we need the OID of --TESTCD (if any) and the complete name :)
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and its full name :)
    let $testcdname := $definedoc//odm:ItemDef[@OID=$testcdoid]/@Name
    (: get the location of the dataset and the document itself :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: Iterate over all records in the dataset for which there is a --TESTCD variable :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData/@ItemOID=$testcdoid]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $testcd := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
        (: The value of --TESTCD is not allowed to be 'OTHER' (case insensitive?)  :)
        where upper-case($testcd) = 'OTHER'
        return <error rule="CG0341" dataset="{data($name)}" variable="{data($testcdname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of {data($testcdname)}='{data($testcd)}' is not allowed to be equal to 'OTHER'</error>						
		
	