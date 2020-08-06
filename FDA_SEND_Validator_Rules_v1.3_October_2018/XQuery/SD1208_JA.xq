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

(: Rule SD1208: RFXSTDTC date is after RFXENDTC (DM) - 
Only applies to SENDIG 3.1, not to 3.0 :)
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
let $definedoc := doc(concat($base,$define))
(: get the DM dataset and the OID of DM.RFXENDTC (Date/Time of Last Study Treatment)  :)
let $dmdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
(: and get the location and the DM document itself :)
let $dmlocation := (
	if($defineversion='2.1') then $dmdef/def21:leaf/@xlink:href
	else $dmdef/def:leaf/@xlink:href
)
let $dmdoc := doc(concat($base,$dmlocation))
(: we need the OID of USUBJID in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: and of RFXENDTC :)
let $rfxendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFXENDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
)
(: and of RFXSTDTC :)
let $rfxstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFXSTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
) 
(: iterate over all records in DM that have both RFXSTDTC and RFXENDTC :)
for $record in $dmdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rfxstdtcoid]/@Value and odm:ItemData[@ItemOID=$rfxendtcoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of RFXSTDTC and RFENDTC :)
        let $rfxstdtcvalue := $record/odm:ItemData[@ItemOID=$rfxstdtcoid]/@Value
        let $rfxendtcvalue := $record/odm:ItemData[@ItemOID=$rfxendtcoid]/@Value
        (: take care that both are comparable as dateTime :)
        let $rfxstdtctestvalue := (
            (: only the year is given :)
            if(string-length($rfxstdtcvalue) = 4) then concat($rfxstdtcvalue,'-01-01T00:00:00')
            (: only the month is given :)
            else if(string-length($rfxstdtcvalue) = 7) then concat($rfxstdtcvalue,'-01T00:00:00')
            (: complete date is given but no time :)
            else if(string-length($rfxstdtcvalue) = 10) then concat($rfxstdtcvalue,'T00:00:00')
            (: T is given but no hours - might bei invalid anyway :)
            else if(string-length($rfxstdtcvalue) = 11) then concat($rfxstdtcvalue,'00:00:00')
            (: only hour is given :)
            else if(string-length($rfxstdtcvalue) = 13) then concat($rfxstdtcvalue,':00:00')
            (: hour and minutes are given, but no seconds :)
            else if(string-length($rfxstdtcvalue) = 16) then concat($rfxstdtcvalue,':00')
            (: all ok anyway :)
            else ($rfxstdtcvalue)
        )
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
        (: RFXENDTC value must be equal or higher than RFXSTDTC - but first check whether it really is a datetime :)
            where $rfxstdtctestvalue castable as xs:dateTime and $rfxendtctestvalue castable as xs:dateTime and xs:dateTime($rfxstdtctestvalue) > xs:dateTime($rfxendtctestvalue) 
            return <error rule="SD1208" dataset="DM" variable="RFXSTDTC" rulelastupdate="2020-06-25" recordnumber="{data($recnum)}">RFXSTDTC={data($rfxstdtcvalue)} is after RFXENDTC={data($rfxendtcvalue)} in dataset DM</error>	

