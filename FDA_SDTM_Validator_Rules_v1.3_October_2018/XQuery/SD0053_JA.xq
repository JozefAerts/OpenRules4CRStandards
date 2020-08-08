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
	
(: Rule SD0053 - ARM is not 'Not Assigned', when ARMCD equals 'NOTASSGN', or vice versa
Description of Arm (ARM) must equal 'Not Assigned', when Arm Code (ARMCD) is 'NOTASSGN', and vice versa
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
(: get the DM and TA dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM' or @Name='TA']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation:= concat($base,$datasetname)
    (: and get the OIDs of ARMCD and ARM :)
    let $armcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
)
let $armoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the dataset :)
for $record in doc($datasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values for ARMCD and ARM :)
    let $armcdvalue := $record/odm:ItemData[@ItemOID=$armcdoid]/@Value
    let $armvalue := $record/odm:ItemData[@ItemOID=$armoid]/@Value
    (: in case that ARMCD=NOTASSGN then ARM must be 'Not Assigned' and vice versa - CASE SENSITIVE :)
    where ($armcdvalue='NOTASSGN' and not($armvalue='Not Assigned')) or ($armvalue='Not Assigned' and not($armcdvalue='NOTASSGN'))
    (: and give out an error message :)
    return <error rule="SD0053" dataset="{data($name)}" variable="ARM" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">ARM is not 'Not Assigned', when ARMCD equals 'NOTASSGN', or vice versa. ARMCD={data($armcdvalue)} with ARM={data($armvalue)} was found</error>
