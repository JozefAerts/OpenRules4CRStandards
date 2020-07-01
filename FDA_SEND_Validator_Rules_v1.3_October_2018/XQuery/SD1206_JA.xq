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

(: Rule SD1206: EXSTDTC date is after RFXENDTC - 
only applies to SENDIG v.3.1, not to 3.0 :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the DM dataset and the OID of DM.RFXENDTC (Date/Time of Last Study Treatment)  :)
let $dmdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
(: and get the location and the DM document itself :)
let $dmlocation := $dmdef/def:leaf/@xlink:href
let $dmdoc := doc(concat($base,$dmlocation))
(: we also need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: and of RFXENDTC :)
let $rfxendtcoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RFXENDTC']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: create a temporary structure containing USUBJID and RFPENDTC :)
let $usubjidrfxendtcpairs := (
    for $record in $dmdoc//odm:ItemGroupData
        let $usubjid := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
        let $rfxendtc := $record/odm:ItemData[@ItemOID=$rfxendtcoid]/@Value
    return <record usubjid="{$usubjid}" rfxendtc="{$rfxendtc}" />
)
(: iterate over all EX datasets :)
for $datasetdef in doc(concat($base,$define))//odm:ItemGroupDef[@Domain='EX' or starts-with(@Name,'EX')]
    (: get the dataset name :)
    let $name := $datasetdef/@Name
    let $domain := $datasetdef/@Domain
    (: get the datasetlocation :)
    let $datasetlocation := $datasetdef/def:leaf/@xlink:href
    (: we need the OID of USUBJID and of the EXSTDTC variable :)
    let $exstdtcoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='EXSTDTC']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $usubjidoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: now iterate over all records that do have a value for --EXSTDTC :)
    for $record in doc(concat($base,$datasetlocation))//odm:ItemGroupData[odm:ItemData[@ItemOID=$exstdtcoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --ENDTC and of USUBJID :)
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $exstdtcvalue := $record/odm:ItemData[@ItemOID=$exstdtcoid]/@Value
        (: get the value of RFPENDTC in DM from the temporary structure :)
        let $rfxendtcvalue := $usubjidrfxendtcpairs[@usubjid=$usubjidvalue]/@rfpendtc
        (: take care of incomplete dates :)
        let $exstdtctestvalue :=
                (: only the year is given :)
                if(string-length($exstdtcvalue) = 4) then concat($exstdtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($exstdtcvalue) = 7) then concat($exstdtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                else if(string-length($exstdtcvalue) = 10) then concat($exstdtcvalue,'T00:00:00')
                (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($exstdtcvalue) = 11) then concat($exstdtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($exstdtcvalue) = 13) then concat($exstdtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($exstdtcvalue) = 16) then concat($exstdtcvalue,':00')
                (: all ok anyway :)
                else ($exstdtcvalue)
        (: and also for RFXENDTC :)
        let $rfxendtctestvalue := (
            (: only the year is given :)
                if(string-length($rfxendtcvalue) = 4) then concat($rfxendtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($rfxendtcvalue) = 7) then concat($rfxendtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                else if(string-length($rfxendtcvalue) = 10) then concat($rfxendtcvalue,'T00:00:00')
                (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($rfxendtcvalue) = 11) then concat($rfxendtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($rfxendtcvalue) = 13) then concat($rfxendtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($rfxendtcvalue) = 16) then concat($rfxendtcvalue,':00')
                (: all ok anyway :)
                else ($rfxendtcvalue)
        )
        (: compare both values :)
        (: RFXENDTC value must be equal or higher than EXSTDTC - but first check whether it really is a datetime :)
            where $exstdtctestvalue castable as xs:dateTime and $rfxendtctestvalue castable as xs:dateTime and xs:dateTime($exstdtctestvalue) > xs:dateTime($rfxendtctestvalue) 
            return <error rule="SD1206" dataset="{data($name)}" variable="EXSTDRC" rulelastupdate="2020-06-25" recordnumber="{data($recnum)}">EXSTDTC={data($exstdtcvalue)} is after RFXENDTC={data($rfxendtcvalue)} in dataset {data($name)}</error>	

