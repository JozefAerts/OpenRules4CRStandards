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

(: Rule SD0028 - Value for --STNRHI is less than value for --STNRLO:
Reference Range Upper Limit-Std Units (--STNRHI) value must be greater than or equal to Reference Range Lower Limit-Std Units (--STNRLO) value
:)
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

(: iterate over all FINDINGS datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the STNRHI and STNRLO variables :)
    let $stnrhioid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STNRHI')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $stnrihname := doc(concat($base,$define))//odm:ItemDef[@OID=$stnrhioid]/@Name
    let $stnrlooid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STNRLO')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $stnrloname := doc(concat($base,$define))//odm:ItemDef[@OID=$stnrlooid]/@Name
    (: iterate over all records for which there is as well a populated STNRHI as STNTLO data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$stnrlooid] and odm:ItemData[@ItemOID=$stnrhioid]][@data:ItemGroupDataSeq<10]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get both the values :)
        let $stnrlovalue := $record/odm:ItemData[@ItemOID=$stnrlooid]/@Value
        let $stnrhivalue := $record/odm:ItemData[@ItemOID=$stnrhioid]/@Value
        (: convert to numeric and compare both values :)
        (: --STNRHI must not be smaller than STNRLO :)
        where number($stnrhivalue) < number($stnrlovalue)
        return <error rule="SD0028" dataset="{data($name)}" variable="{data(stnrihname)}" rulelastupdate="2019-08-18" recordnumber="{data($recnum)}">Value for {data($stnrihname)}, value={data($stnrhivalue)} is less than value for {data($stnrloname)}, value={data($stnrlovalue)}</error>
