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
	
(: Rule SD1127 - Inconsistent value for --TPTNUM within --TPT:
All values of Planned Time Point Number (--TPTNUM) variable should be the same for a given value of Planned Time Point Name (--TPT) variable :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all provided datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation:= concat($base,$dsname)
    (: and get the OIDs of --TPT and --TPTNUM :)
    let $tptoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := doc(concat($base,$define))//odm:ItemDef[@OID=$tptoid]/@Name
    let $tptnumoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptnumname := doc(concat($base,$define))//odm:ItemDef[@OID=$tptnumoid]/@Name
    (: Get all unique values of --TPT :)
    let $tptuniquevalues := distinct-values(doc($datasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$tptoid]/@Value)
    (: iterate over the unique TPTNUM values and get the records :)
    for $tptuniquevalue in $tptuniquevalues
        (: get all the records :)
        let $uniquetptrecords := doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptoid][@Value=$tptuniquevalue]]
        (: get the unique values for TPTNUM within each of the unique TPT values, and count them :)
        let $uniquetptnumvalues := distinct-values($uniquetptrecords/odm:ItemData[@ItemOID=$tptnumoid]/@Value)
        let $uniquetptnumvaluescount := count($uniquetptnumvalues)
        (: the value of the count of unique TPT values for each TPTNUM must be 1 :)
        where not($uniquetptnumvaluescount = 1) 
        return <warning rule="SD1127" dataset="{data($name)}" variable="{data($tptnumname)}" rulelastupdate="2019-08-29">Inconsistent value for {data($tptnumname)} within {data($tptname)} in dataset {data($datasetname)}. {data($uniquetptnumvaluescount)} different {data($tptnumname)} values were found for {data($tptname)}={data($tptuniquevalue)}</warning>			
