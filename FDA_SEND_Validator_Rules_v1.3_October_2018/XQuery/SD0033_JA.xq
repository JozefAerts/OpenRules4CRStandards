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
	
(: Rule SD0033 - Missing value for --TPTNUM, when --TPT is provided:
Planned Time Point Number (--TPTNUM) variable must be included into the domain, when Planned Time Point Name (--TPT) variable is present
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all the datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef
    let $name := $dataset/@Name 
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname) 
    (: Get the OIDs of TPT and TPTNUM (if any) :)
    let $tptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptname := doc(concat($base,$define))//odm:ItemDef[@OID=$tptoid]/@Name
    (: Get the OIDs of TPT and TPTNUM (if any) :)
    let $tptnumoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $tptnumname := doc(concat($base,$define))//odm:ItemDef[@OID=$tptnumoid]/@Name
    (: iterate over the records in the dataset that do have a TPT  :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptoid]]
        let $recnum := $record/@data:ItemGroupDataSeq 
		(: Get the -TPT value :)
        let $tptvalue := $record/odm:ItemData[@ItemOID=$tptoid]/@Value
		(: Report when --TPTNUM is absent :)
        where not($record/odm:ItemData[@ItemOID=$tptnumoid])
        return <warning rule="SD0033" rulelastupdate="2019-09-05" recordnumber="{data($recnum)}">Planned Time Point Number {data($tptnumname)} may not be NULL, when Planned Time Point Name {data($tptname)} is populated, value = {data($tptvalue)}</warning>
