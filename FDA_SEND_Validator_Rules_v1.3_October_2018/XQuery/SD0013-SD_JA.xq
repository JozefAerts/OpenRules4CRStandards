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

(: Rule SD0013 - --STDTC is after --ENDTC 
Start Date/Time of Event, Exposure or Observation (--STDTC) must be less or equal to End Date/Time of Event, Exposure or Observation (--ENDTC) 
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
declare variable $datasetname external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets :)
for $dataset in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($dsname) then doc(concat($base,$dsname))
		else ()
	)
    (: get the prefix for STDTC and ENDTC from either the domain or the dataset name :)
    let $prefix := if($dataset/@Domain) then $dataset/@Domain
        else substring($name,1,2)
    (: Get the OIDs of the --STDTC and --ENDTC variables :)
    (: We must iterate over all xxSTDTC and xxxSTDTC and xxxxSTDTC :)
    let $stdtcoids := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    for $stdtcoid in $stdtcoids
        let $stdtcname :=  $definedoc//odm:ItemDef[@OID=$stdtcoid]/@Name
        (: get the corresponding ENDTC :)
        let $endtcoid := (
            for $a in $definedoc//odm:ItemDef[@Name=replace($stdtcname,'STDTC','ENDTC')]/@OID 
            where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
            return $a
        )
        let $endtcname :=  $definedoc//odm:ItemDef[@OID=$endtcoid]/@Name
        (: now iterate over all the records in the dataset that do have an SDTY AND ENDY variable :)
        for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid] and odm:ItemData[@ItemOID=$endtcoid]]
            let $recnum := $record/@data:ItemGroupDataSeq
            (: get the values :)
            let $stdtcvalue := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
            let $endtcvalue := $record/odm:ItemData[@ItemOID=$endtcoid]/@Value
            (: take care that both are datetime, as it can be that only one of the two is of datetime 
            and that the other is of type date, which would make them incomparable :)
            (: first for --STDTC  :)
            let $stdtctestvalue :=
                        (: only the year is given :)
                        if(string-length($stdtcvalue) = 4) then concat($stdtcvalue,'-01-01T00:00:00')
                        (: only the month is given :)
                        else if(string-length($stdtcvalue) = 7) then concat($stdtcvalue,'-01T00:00:00')
                        (: complete date is given but no time :)
                         else if(string-length($stdtcvalue) = 10) then concat($stdtcvalue,'T00:00:00')
                        (: T is given but no hours - might bei invalid anyway :)
                        else if(string-length($stdtcvalue) = 11) then concat($stdtcvalue,'00:00:00')
                        (: only hour is given :)
                        else if(string-length($stdtcvalue) = 13) then concat($stdtcvalue,':00:00')
                        (: hour and minutes are given, but no seconds :)
                        else if(string-length($stdtcvalue) = 16) then concat($stdtcvalue,':00')
                        (: all ok anyway :)
                        else ($stdtcvalue)
            (: and then for --ENDTC :)
            let $endtctestvalue :=
                        (: only the year is given :)
                        if(string-length($endtcvalue) = 4) then concat($endtcvalue,'-01-01T00:00:00')
                        (: only the month is given :)
                        else if(string-length($endtcvalue) = 7) then concat($endtcvalue,'-01T00:00:00')
                        (: complete date is given but no time :)
                         else if(string-length($endtcvalue) = 10) then concat($endtcvalue,'T00:00:00')
                        (: T is given but no hours - might bei invalid anyway :)
                        else if(string-length($endtcvalue) = 11) then concat($endtcvalue,'00:00:00')
                        (: only hour is given :)
                        else if(string-length($endtcvalue) = 13) then concat($endtcvalue,':00:00')
                        (: hour and minutes are given, but no seconds :)
                        else if(string-length($endtcvalue) = 16) then concat($endtcvalue,':00')
                        (: all ok anyway :)
                        else ($endtcvalue)
            where $stdtctestvalue castable as xs:dateTime and $endtctestvalue castable as xs:dateTime and xs:dateTime($stdtctestvalue) > xs:dateTime($endtctestvalue) 
            return <error rule="SD0013" dataset="{data($name)}" variable="{data($stdtcname)}" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">{data($stdtcname)}={data($stdtcvalue)} is after {data($endtcname)}={data($endtcvalue)} in dataset {data($datasetname)}</error>	
