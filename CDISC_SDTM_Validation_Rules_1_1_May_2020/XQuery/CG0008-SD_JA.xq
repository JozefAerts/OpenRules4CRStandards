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

(: Rule CG0008 - --ELTM must be null when --TPTREF is null
Precondition: --TPTREF = null
Rule: --ELTM = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(:  let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'lb' :)
(: iterate over all datasets except for DM :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: Get the OID of the TPTREF and ELTM variable (when present) :)
    let $tptrefoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: let $tptrefname := doc(concat($base,$define))//odm:ItemDef[@OID=$tptrefoid]/@Name :)
    let $tptrefname := concat($name,'TPTREF')
    let $eltmoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $eltmname := doc(concat($base,$define))//odm:ItemDef[@OID=$eltmoid]/@Name
    (: iterate over all the records that do have an ELTM data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$eltmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of the TPTREF and ELTM data points (if any) :)
        let $tptrefvalue := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value
        let $eltmvalue := $record/odm:ItemData[@ItemOID=$eltmoid]/@Value 
        (: when TPTREF is null, --ELTM must be null :)
        where not($tptrefvalue) and  $eltmvalue
        return <error rule="CG0008" variable="{data($tptrefname)}" dataset="{data($name)}" rulelastupdate="2020-06-10" recordnumber="{data($recnum)}">Missing value for {data($eltmname)} is not null although {data($tptrefname)} is not populated, value of {data($eltmname)}={data($eltmvalue)}</error>						
