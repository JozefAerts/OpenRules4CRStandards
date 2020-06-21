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

(: Rule CG0522: DM: When ACTARMCD = null, then ACTARM = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DM dataset :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARMCD, ACTARM :)
    let $actarmcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $actarmoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARM']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that do NOT have ACTARMCD populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$actarmcdoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARM :)
        let $actarmvalue := $record/odm:ItemData[@ItemOID=$actarmoid]/@Value
        (: Give an error when ACTARM is populated :)
        where $actarmvalue
        return <error rule="CG0522" dataset="DM" variable="ACTARM" rulelastupdate="2020-06-21" recordnumber="{data($recnum)}">ACTARM has value '{data($actarmvalue)}' although ACTARMCD is null</error>
	
	