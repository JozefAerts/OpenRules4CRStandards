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

(: Rule SD1051 - Unexpected value for IDVAR/IDVARVAL: 
Both Identifying Variable (IDVAR) and Identifying Variable Value (IDVARVAL) should not be populated, when relating information to the Demographics (DM) domain 
in SUPPxx datasets
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
(: iterate over all SUPPxx datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP')]
    let $name := $dataset/@Name
    let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OIDs of the IDVAR and IDVARVAL and RDOMAIN variables :)
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $idvarvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all records in the dataset :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values for the IDVAR, IDVARVAL and RDOMAIN variables :)
        let $idvarvalue := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
        let $idvarvalvalue := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
        let $rdomainvalue := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        (: When RDOMAIN=DM IDVAR and IDVARVAL may not have a value :)
        where $rdomainvalue='DM' and ($idvarvalue or $idvarvalvalue)
        return <warning rule="SD1051" variable="IDVAR" dataset="{data($name)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Unexpected value for IDVAR/IDVARVAL: IDVAR and/or IDVARVAL are populated although RDOMAIN=DM in dataset {data($datasetname)}</warning>
