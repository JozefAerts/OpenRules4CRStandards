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

(: Rule CG0027: The values for --CAT and --SCAT must be different :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all datasets that have a --CAT and --SCAT variable in the interventions, events findings domains and the TI dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Name='TI']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OID of the --CAT variable (if any) :)
    let $catoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'CAT') and string-length(@Name)=5]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $catname := concat($name,'CAT')
    (: Get the OID of the --SCAT variable (if any) :)
    let $scatoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'SCAT') and string-length(@Name)=6]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $scatname := concat($name,'SCAT')
    (: iterate over all records that DO have a CAT AND SCAT value :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$catoid] and odm:ItemData[@ItemOID=$scatoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and compare the values - they MUST NOT be equal :)
        let $catvalue := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        let $scatvalue := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        where $catvalue = $scatvalue
        return <error rule="CG0027" variable="{data($scatname)}" dataset="{$name}" rulelastupdate="2017-02-04" recordnumber="{data($recnum)}">Values for {data($catname)} and {data($scatname)} are identical in dataset {data($datasetname)}</error>				
		 
		