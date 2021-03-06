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
	
(: Rule SD0084 - Negative value for AGE (DM)
The value of Age (AGE) cannot be less than 0
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
let $dmdataset := $definedoc//odm:ItemGroupDef[@Name='DM']
	let $dmdatasetname := (
		if($defineversion='2.1') then $dmdataset/def21:leaf/@xlink:href
		else $dmdataset/def:leaf/@xlink:href
	)
    let $dmdatasetdoc := (
		if($dmdatasetname) then doc(concat($base,$dmdatasetname))
		else ()
	)
    (: find the OID of the AGE variable :)
    let $ageoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AGE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a 
    )
    (: now iterate over all in the dataset itself :)
    for $record in $dmdatasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value :)
        let $agevalue := $record/odm:ItemData[@ItemOID=$ageoid]/@Value
        (: and check whether >= 0 :)
        where $agevalue and number($agevalue) < 0
        return <error rule="SD0084" dataset="DM" variable="AGE" rulelastupdate="2015-02-10" recordnumber="{data($recnum)}">Negative value for AGE in DM dataset {data($dmdatasetname)}: {data($agevalue)} was found</error>
