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

(: Rule CG0068: When Multiple informed consents obtained and DSDECOD = 'INFORMED CONSENT OBTAINED' then earliest DSSTDTC  = DM.RFICDTC :)
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
let $definedoc := doc(concat($base,$define))
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: and the location of the DS dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Get the DM dataset and its location :)
let $dmitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetdoc := doc(concat($base,$dmdatasetlocation))
(: get the OID of USUBJID and of DSDECOD in DS :)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and the OID of DSSTDTC :)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the OID of USUBJID and of RFICDTC in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dmrficdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
    where $a = $dmitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all records in DS that have DSDECOD='INFORMED CONSENT OBTAINED' and group them by USUBJID :)
 let $orderedrecords := (
    for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsdecodoid and @Value='INFORMED CONSENT']]
        group by 
        $b := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
        return element group {  
            $record
        }
    )	
(: each group now has the same value for USUBJID and contains one or more ItemGroupData (i.e. records) :)
(: get the values (as an array) of DSSTDTC :)
for $group in $orderedrecords
    let $usubjidvalue := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
    let $informedconsentdates := $group/odm:ItemGroupData/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
    (: and take the lowest (earliest) value :)
    (: we use a little trick here, we transform the date into a number :)
    let $earliestinformedconsentdateasnumber := min(number(replace($informedconsentdates,'-','')))
    (: recover the earliest number into a date again - TODO :)
    (: let $earliestinformedconsentdate := concat(substring($earliestinformedconsentdateasnumber,1,4),'-')  :)
    (: This date must also appear as the value of USUBJID in DM :)
    let $dminformedconsentdate := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjidvalue]]/odm:ItemData[@ItemOID=$dmrficdtcoid]/@Value
    (: again, make it a number :)
    let $dminformedconsentdatenumber := number(replace($dminformedconsentdate,'-',''))
    (: both have to equal - but beware of absent informed content dates in DM :)
    where $dminformedconsentdate and not($dminformedconsentdatenumber = $earliestinformedconsentdateasnumber)
    return <error rule="CG0068" variable="DSDECOD" dataset="DS" rulelastupdate="2017-02-06">For subject USUBJID='{data($usubjidvalue)}', the earliest informed consent date in DS (DSDECOD='INFORMED CONSENT OBTAINED') does not correspond to the informed consent date RFICDTC={data($dminformedconsentdate)} in DM. The earliest informed consent date found in DS is '{data($earliestinformedconsentdateasnumber)}'</error>
	