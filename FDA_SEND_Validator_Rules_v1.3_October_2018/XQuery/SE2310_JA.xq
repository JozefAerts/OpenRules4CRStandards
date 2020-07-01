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
	
(: Rule SE2310 - Value for --STRESC is populated, when --STAT is 'NOT DONE'
Status (--STAT) should be NULL, Standardized Result in Character Format (--STRESC ) is provided
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $datasetname := 'LB' :)
(: iterate over all provided datasets within SC, BW, BG, FW, LB, DD, CL, MI, MA, OM, PM, PC, PP, TF, EG, VS :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][@Domain='SC' or @Domain='BW' or @Domain='BG' or @Domain='FW' or @Domain='LB' or @Domain='DD' or @Domain='CL' or @Domain='MI' or @Domain='MA' or @Domain='OM' or @Domain='PM' or @Domain='PC' or @Domain='PP' or @Domain='TF' or @Domain='EG' or @Domain='VS']
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: get the OIDs of the --STAT and --STRESC variable :)
    let $statoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname := doc(concat($base,$define))//odm:ItemDef[@OID=$statoid]/@Name
    let $strescoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $strescname := doc(concat($base,$define))//odm:ItemDef[@OID=$strescoid]/@Name
    (: iterate over all records for which STRESC is populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$strescoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of STAT  :)
        let $statvalue := $record/odm:ItemData[@ItemOID=$statoid]/@Value
        (: STAT must be null :)
        where $statvalue
        return <warning rule="SE2310" dataset="{data($name)}" variable="{data($statname)}" rulelastupdate="2019-08-18" recordnumber="{data($recnum)}">Status {data($statname)} should be NULL, when Result or Finding in Original Units ({data($strescname)}) is provided
        </warning>
