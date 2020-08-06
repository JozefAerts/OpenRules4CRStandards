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
		
(: Rule SD2023 - AGE is not provided:
Age (AGE) variable values should be provided, when Date/Time of Birth (BRTHDTC) variable values are populated
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
(: Get the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetname))
    (: get the OID of the AGE, and BRTHDTC (when present) :)
    let $ageoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AGE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $brthdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name='BRTHDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have BRTHDTC populated :)
    for $record in datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$brthdtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values of AGE (when populated) :)
        let $agevalue := $record/odm:ItemData[@ItemOID=$ageoid]/@Value
        (: AGE must be populated :)
        where not($agevalue)
        return <error rule="SD2023" dataset="DM" variable="AGE" rulelastupdate="2020-06-25" recordnumber="{data($recnum)}">AGE is not provided</error>
