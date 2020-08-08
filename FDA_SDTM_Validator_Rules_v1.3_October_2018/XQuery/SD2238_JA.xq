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

(:  Rule SD2238: Inconsistent value for --STTPT - Start Reference Time Point (--STTPT) value must be consistent for all records with same Subject (USUBJID) and Start Date/Time (--STDTC) values :)
(: Applies to INTERVENTIONS, EVENTS :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: iterate over all INTERVENTIONS and EVENTS datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS']
    (: get the name :)
    let $name := $datasetdef/@Name
    (: get the dataset location and the dataset document itself :)
    let $datasetloc := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetloc))
    (: we need the OID of USUBJID, --STTPT and --STDTC :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $sttptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STTPT')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $sttptname := $definedoc//odm:ItemDef[@OID=$sttptoid]/@Name
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdtcname := $definedoc//odm:ItemDef[@OID=$stdtcoid]/@Name
    (: return <test>{data($usubjidoid)} - {data($sttptoid)} - {data($stdtcoid)}</test> :)
    (: group the records by USUBJID and --STDTC - 
    all the records in each group will have the same value for USUBJID and --STDTC:)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData
            group by 
            $b := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value,
            $c := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
            return element group {  
                $record
            }
    )
    (: Each group now has the same value for USUBJID and --STDTC - 
    iterate over all the groups what DO have a value for USUBJID, --STTPT and --STDTC:)
    for $group in $orderedrecords[$usubjidoid and $stdtcoid and $sttptoid]
        (: get the values of USUBJID and --STDTC :)
        let $usubjid := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $stdtc := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$stdtcoid]/@Value
        (: and the value of --STTPT and then record number:)
        let $sttpt1 := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$sttptoid]/@Value
        let $recnum1 := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        (: now iterate over all other records in the same group: 
        the value of --STTPT should be the same as in the first record in the group :)
        for $record in $group/odm:ItemGroupData[position()>1]
            (: get the value of --STTPT and the record number :)
            let $sttpt2 := $record/odm:ItemData[@ItemOID=$sttptoid]/@Value
            let $recnum2 := $record/@data:ItemGroupDataSeq
            (: the two --STTPT values must be equal :)
            where not($sttpt1 = $sttpt2)
            return <error rule="SD2238" dataset="{$name}" variable="{data($sttptname)}" rulelastupdate="2020-08-08" recordnumber="{$recnum2}">Inconsistent value for {data($sttptname)}: Record {data($recnum2)} has {data($sttptname)}={data($sttpt2)} whereas recordnumber={data($recnum1)} has {data($sttptname)}={data($sttpt1)} for the same value of USUBJID='{data($usubjid)}' and {data($stdtcname)}='{data($stdtc)}'</error>  	
	
	