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

(: Rule CG0220 - When --STDTC and DM.RFSTDTC both contain complete values in their date portion then --STDY is properly calculated per study day algorithm OR (FDA-CG0220) :
Study Day of Start (--STDY) variable value should be populated as defined by CDISC standards: --STDY = (date portion of --STDTC) - (date portion of RFSTDTC) +1 if --STDTC is on or after RFSTDTC; --STDY = (date portion of --STDTC) - (date portion of RFSTDTC) if --STDTC precedes RFSTDTC.
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
let $definedoc := doc(concat($base,$define))
(: Get the location of the DM dataset :)
let $dmdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
let $dmdatasetlocation := concat($base,$dmdataset)
(: get the OID of the RFSTDTC variable :)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a   
)
(: get the OID of the USUBJID variable :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a  
)
(: iterate over all other datasets :)
for $datasetdef in doc(concat($base,$define))//odm:ItemGroupDef[not(@Name='DM')][@Name=$datasetname]
    let $name := $datasetdef/@Name
    let $dsname := $datasetdef/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: Get the OIDs of the --DY and --DTC variables  :)
    let $stdyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDY') and string-length(@Name)=6]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdyname := concat($name,'STDY')
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC') and string-length(@Name)=7]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    ) 
    let $stdtcname := $datasetdef//odm:ItemDef[@OID=$stdtcoid]/@Name 
    (: and the OID of the USUBJID variable (might be different from the one in DM) :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: get the --DTC value :)
        let $stdtcvalue := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
        (: and check whether it is a complete date - i.e. string-length at least 10 :)
        let $iscompletestdtcvalue := string-length($stdtcvalue) >= 10  (: boolean :)
        (: look up the record in the DM dataset and get the RFSTDTC :)
        (: taking the worst case scenario into account that there is more than one record for a USUBJID in DM - take the first one :)
        let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: and check whether also RFSTDTC is complete :)
        let $iscompleterfstdtcvalue := string-length($rfstdtcvalue) >= 10 (: boolean :)
        let $stdyvalue := $record/odm:ItemData[@ItemOID=$stdyoid]/@Value
        (: now calculate the DY value but only when RFSTDTC and STDTC have a complete date part :)
        let $stdycalculated := (
            if ($iscompleterfstdtcvalue and $iscompletestdtcvalue) then
                (: if there is one, we must strip off the time part :)
                let $stdtcvalueshort := substring($stdtcvalue,1,10)
                let $rfstdtcvalueshort := substring($rfstdtcvalue,1,10)
                let $stdycalc := (
                    if($stdtcvalueshort castable as xs:date and $rfstdtcvalueshort castable as xs:date) then
                        days-from-duration(xs:date($stdtcvalueshort)-xs:date($rfstdtcvalueshort))
                    else()
                ) 
                return $stdycalc
            else ()  (: one or both dates are not complete dates :)
        )
        (: for the FDA there is no day 0, DY can only be <0 or >0, first day is day 1 :)
        let $stdycalculatedfda := (
            if($stdycalculated >= 0) then
                $stdycalculated + 1
            else (
                $stdycalculated    
            )
        )
        (: before comparing, also check whether the submitted value is really an integer :)
        where $stdyvalue castable as xs:integer and $stdycalculatedfda and $stdyvalue and not($stdycalculatedfda = $stdyvalue)
        return <error dataset="{data($name)}" variable="{data($stdyname)}" rule="CG0220" rulelastupdate="2017-02-24" recordnumber="{data($recnum)}">Invalid value for {data($stdyname)}, calculated value={data($stdycalculatedfda)}, observed value={data($stdyvalue)}, in dataset {data($name)} </error>		
		
		