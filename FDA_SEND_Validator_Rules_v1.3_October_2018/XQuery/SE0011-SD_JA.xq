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

(: Rule SE0011: Time Point Reference should be provided, when Reference Time Point is used.
 Time Point Reference (--TPTREF) variable values should be provided, when Date/Time of Reference Time Point (--RFTDTC) variable values are populated.
 Applicable to: EX, BG, LB, CL, PC, EG, VS
 IMPORTANT REMARK: this also applies to SDTM, not only to SEND :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
(: find all dataset definitions  :)
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml'
let $datasetname := 'LB' :)
(: get the define.xml dataset definition :)
let $definedoc := doc(concat($base,$define))
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Domain='EX' or @Domain='BG' or @Domain='LB' or @Domain='CL' or @Domain='PC' or @domain='EG' or @Domain='VS']
    (: get the name location of the dataset :)
    let $name := $datasetdef/@Name
    let $datasetlocation := $datasetdef/def:leaf/@xlink:href
    (: and the document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of --TPTREF and --RFTDTC, and their name :)
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    ) 
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name
    let $rftdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'RFTDTC')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    let $rftdtcname := $definedoc//odm:ItemDef[@OID=$rftdtcoid]/@Name
    (: iterate over all records that have --RFTDTC :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rftdtcoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --TPTREF, if any :)
        let $tptrefvalue := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value
        (: the value of -TPTREF is not allowed to be null or empty :)
        (: where not($tptrefvalue) or $tptrefvalue='' :)
        return <warning rule="SE0011" dataset="{$name}" variable="{$rftdtcname}" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">{data($tptrefname)} is not populated although {data($rftdtcname)} is populated</warning>	

