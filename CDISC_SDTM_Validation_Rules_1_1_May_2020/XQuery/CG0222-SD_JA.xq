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

(: Rule CG0222 - When --ENDTC and DM.RFSTDTC both contain complete values in their date portion then --ENDY is properly calculated per study day algorithm :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $domain external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the location of the DM dataset :)
let $dmdataset := $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
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
for $datasetdef in doc(concat($base,$define))//odm:ItemGroupDef[not(@Name='DM') and @Name=$domain]
    let $name := $datasetdef/@Name
    let $domain := $datasetdef/@Domain
    let $datasetname := $datasetdef/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: Get the OIDs of the ENDY and ENDTC variables  :)
    let $endyoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDY') and string-length(@Name)=6]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: generate the xxENDY full name, as it may not be present in the dataset :)
    let $endyname := (
        if($domain) then concat($domain,'ENDY')
        else concat(substring($name,1,2),'ENDY')  
    )
    let $endtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENDTC') and string-length(@Name)=7]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    ) 
    let $endtcname := doc(concat($base,$define))//odm:ItemDef[@OID=$endtcoid]/@Name 
    (: and the OID of the USUBJID variable (might be different from the one in DM) :)
    let $usubjidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records that have an ENDTC data point  :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$endtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: get the --DTC value :)
        let $endtcvalue := $record/odm:ItemData[@ItemOID=$endtcoid]/@Value
        (: and check whether it is a complete date - i.e. string-length at least 10 :)
        let $iscompletestdtcvalue := string-length($endtcvalue) >= 10  (: boolean :)
        (: look up the record in the DM dataset and get the RFSTDTC :)
        (: taking worst case scenario into account that there is more than 1 record for a USUBJID in DM - take the first one :)
        let $rfstdtcvalue := doc($dmdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]][1]/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
        (: and check whether also RFSTDTC is complete :)
        let $iscompleterfstdtcvalue := string-length($rfstdtcvalue) >= 10 (: boolean :)
        let $endyvalue := $record/odm:ItemData[@ItemOID=$endyoid]/@Value
        (: now calculate the DY value but only when RFSTDTC and ENDTC have a complete date part :)
        let $endycalculated := (
            if ($iscompleterfstdtcvalue and $iscompletestdtcvalue) then
                (: if there is one, we must strip off the time part :)
                let $endtcvalueshort := substring($endtcvalue,1,10)
                let $rfstdtcvalueshort := substring($rfstdtcvalue,1,10)
                let $endycalc := (
                    if($endtcvalueshort castable as xs:date and $rfstdtcvalueshort castable as xs:date) then
                        days-from-duration(xs:date($endtcvalueshort)-xs:date($rfstdtcvalueshort))
                    else()
                ) 
                return $endycalc
            else ()  (: one or both dates are not complete dates :)
        )
        (: for the FDA there is no day 0, DY can only be <0 or >0, first day is day 1 :)
        let $endycalculatedfda := (
            if($endycalculated >= 0) then
                $endycalculated + 1
            else (
                $endycalculated    
            )
        )
        (: before comparing, check that the submitted ENDY value is really an integer :)
        where $endyvalue castable as xs:integer and $endycalculatedfda and $endyvalue and not($endycalculatedfda = $endyvalue)
        return <error rule="CG0222" dataset="{data($name)}" variable="{data($endyname)}" rulelastupdate="2020-06-15" recordnumber="{data($recnum)}">Invalid value for {data($endyname)}, calculated value={data($endycalculatedfda)}, observed value={data($endyvalue)}, in dataset {data($datasetname)} </error>				
		
	