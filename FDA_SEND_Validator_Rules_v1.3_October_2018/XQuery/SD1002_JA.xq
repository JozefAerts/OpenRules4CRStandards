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

(: Rule SD1002 - RFSTDTC is after RFENDTC
Subject Reference Start Date/Time (RFSTDTC) must be less than or equal to Subject Reference End Date/Time (RFENDTC)
:)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the DM dataset :)
let $dmdataset := $definedoc//odm:ItemGroupDef[@Name='DM']
let $dmdatasetname := (
	if($defineversion='2.1') then $dmdataset/def21:leaf/@xlink:href
	else $dmdataset/def:leaf/@xlink:href
)
let $dmdatasetdoc := (
	if($dmdatasetname) then doc(concat($base,$dmdatasetname))
	else ()
)
(: and get the OIDs of USUBJID :)
let $usubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
(: and the OIDs for RFSTDTC RFENDTC :)
let $rfstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFSTDTC']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a
)
let $rfendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFENDTC']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
    return $a   
)
(: iterate over all records in the DM dataset :)
for $record in $dmdatasetdoc//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and get the values for USUBJID and ARMCD and RFSTDTC :)
    let $rfstdtcvalue := $record/odm:ItemData[@ItemOID=$rfstdtcoid]/@Value
    let $rfendtcvalue := $record/odm:ItemData[@ItemOID=$rfendtcoid]/@Value
    let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
    (: except for the case that ARMCD=SCRNFAIL or NOTASSGN, there MUST be an RFSTDTC :)
    (: convert RFSTDTC and RFENDTC to a datetime for the case that one of both is a datetime 
    (or partial) and the other is not making them essentally incomparable :)
    let $rfstdtctestvalue :=
                (: only the year is given :)
                if(string-length($rfstdtcvalue) = 4) then concat($rfstdtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($rfstdtcvalue) = 7) then concat($rfstdtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                 else if(string-length($rfstdtcvalue) = 10) then concat($rfstdtcvalue,'T00:00:00')
                (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($rfstdtcvalue) = 11) then concat($rfstdtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($rfstdtcvalue) = 13) then concat($rfstdtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($rfstdtcvalue) = 16) then concat($rfstdtcvalue,':00')
                (: all ok anyway :)
                else ($rfstdtcvalue)
    (: and then for --ENDTC :)
    let $endtctestvalue :=
                (: only the year is given :)
                if(string-length($rfendtcvalue) = 4) then concat($rfendtcvalue,'-01-01T00:00:00')
                (: only the month is given :)
                else if(string-length($rfendtcvalue) = 7) then concat($rfendtcvalue,'-01T00:00:00')
                (: complete date is given but no time :)
                 else if(string-length($rfendtcvalue) = 10) then concat($rfendtcvalue,'T00:00:00')
                (: T is given but no hours - might bei invalid anyway :)
                else if(string-length($rfendtcvalue) = 11) then concat($rfendtcvalue,'00:00:00')
                (: only hour is given :)
                else if(string-length($rfendtcvalue) = 13) then concat($rfendtcvalue,':00:00')
                (: hour and minutes are given, but no seconds :)
                else if(string-length($rfendtcvalue) = 16) then concat($rfendtcvalue,':00')
                (: all ok anyway :)
                else ($rfendtcvalue) 
    where ($rfstdtctestvalue castable as xs:dateTime) and ($rfstdtctestvalue castable as xs:dateTime) and xs:dateTime($rfstdtctestvalue) >  xs:dateTime($endtctestvalue)  
    return <error rule="SD1002" dataset="DM" variable="RFSTDTC" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">RFSTDTC={data($rfstdtcvalue)} is after RFENDTC={data($rfendtcvalue)} for subject with USUBJID={data($usubjidvalue)}</error>
