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
	
(: TODO: "Message" and "Description" in FDA worksheet have a mismatch :)
(: Rule SD0047 - Missing value for --ORRES, when --STAT or --DRVFL is not populated:
Status (--STAT) should be set to 'NOT DONE' or Derived Flag (--DRVFL) should have a value of 'Y', when Result or Finding in Original Units (--ORRES) is NULL
FINDINGS DATASETS
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all provided FINDINGS datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: get the OIDs of the --STAT, --DRVFL and --ORRES variable :)
    let $statoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := doc(concat($base,$define))//odm:ItemDef[@OID=$statoid]/@Name
    let $drvfloid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'DRVFL')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $drvflname := doc(concat($base,$define))//odm:ItemDef[@OID=$drvfloid]/@Name
    let $orresoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ORRES')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $orresname := doc(concat($base,$define))//odm:ItemDef[@OID=$orresoid]/@Name
    (: iterate over all records that do NOT have a value for ORRES :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$orresoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values for STAT and DRVFL :)
        let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        let $drvflvalue := $record/odm:ItemData[@ItemOID=$drvfloid]/@Value
        (: Either STAT='NOT DONE', OR, DRVL='Y' :)
        where not($statvalue='NOT DONE') and not($drvflvalue='Y')
        return <warning rule="SD0047" dataset="{data($name)}" variable="{data($orresname)}" rulelastupdate="2019-08-30" recordnumber="{data($recnum)}">Status {data($statname)} should be set to 'NOT DONE' or Derived Flag {data($drvflname)} should have a value of 'Y', when Result or Finding in Original Units {data($orresname)} is NULL</warning>
