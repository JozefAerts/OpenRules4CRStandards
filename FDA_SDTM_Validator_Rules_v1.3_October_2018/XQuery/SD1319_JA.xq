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

(: Rule SD1319: --STDTC is before RFICDTC - 'All records in Disposition Event (DS) and Protocol Diviation (DV) domains should have Start Date/Time of  Event (--STDTC) equal or after subject's Date/Time of Informed Consent (RFICDTC) in Demographics (DM) domain :)
(: ONLY applies to DV and DS :)
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
let $define := 'define2-0-0-example-sdtm.xml'  :)
let $definedoc := doc(concat($base,$define))
(: get the DM dataset :)
let $dmdatasetdef := $definedoc//odm:ItemGroupDef[@Name='DM']
(: and the location and the document itself :)
let $dmdatasetloc := (
	if($defineversion = '2.1') then $dmdatasetdef/def21:leaf/@xlink:href
	else $dmdatasetdef/def:leaf/@xlink:href
)
let $dmdatasetdoc := doc(concat($base,$dmdatasetloc))
(:  get the OIDs of USUBJID and RFICDTC in DM :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
let $dmrficdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFICDTC']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a
)
(: now create a temporary structure containing the USUBJID-RFICDTC pairs :)
let $rficdtcpairs := (
    for $record in $dmdatasetdoc//odm:ItemGroupData
        let $dmusubjid := $record/odm:ItemData[@ItemOID=$dmusubjidoid]/@Value
        let $rficdtc := $record/odm:ItemData[@ItemOID=$dmrficdtcoid]/@Value
        (: make it a datetime in the case it isn't one yet,
        as -STDTC variables in DS and DV may be datetimes or partialdatetimes:)
        let $rficdtcdt := (
            (: only the year is given - essentially, this should not be allowed :)
            if(string-length($rficdtc) = 4) then concat($rficdtc,'-01-01T00:00:00')
            (: only the year and month is given - essentially, this should not be allowed :)
            else if(string-length($rficdtc) = 7) then concat($rficdtc,'-01T00:00:00')
            (: complete date is given but no time :)
             else if(string-length($rficdtc) = 10) then concat($rficdtc,'T00:00:00')
            (: T is given but no hours - might bei invalid anyway :)
            else if(string-length($rficdtc) = 11) then concat($rficdtc,'00:00:00')
            (: only hour is given :)
            else if(string-length($rficdtc) = 13) then concat($rficdtc,':00:00')
            (: hour and minutes are given, but no seconds :)
            else if(string-length($rficdtc) = 16) then concat($rficdtc,':00')
            (: all ok anyway :)
            else ($rficdtc)
        )
        return <rficdtcpair usubjid="{data($dmusubjid)}" rficdtc="{data($rficdtcdt)}" />
)
(: get the DS and DV dataset :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='DS' or @Domain='DS' or @Name='DV' or @Domain='DV']
    let $name := $datasetdef/@Name
    (: get the location and the dataset document itself :)
    let $datasetloc := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetloc))
    (: get the OID of USUBJID and --STDTC :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $stdtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STDTC')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and the full name of --STDTC :)
    let $stdtcname := $definedoc//odm:ItemDef[@OID=$stdtcoid]/@Name
    (: iterate over all the records that do have a value for --STDTC :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$stdtcoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of USUBJID and -STDTC :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $stdtc := $record/odm:ItemData[@ItemOID=$stdtcoid]/@Value
        (: and look them up in the DM-USUBJID-RFICDTC structure, 
        retrieving the value for RFICDTC for the given subject :)
        let $rficdtc := $rficdtcpairs[@usubjid=$usubjid]/@rficdtc
        (: -DTC must be after RFICDTC - but first need to check for the correct datatype :)
        where $rficdtc castable as xs:dateTime and $stdtc castable as xs:dateTime and xs:dateTime($stdtc) < xs:dateTime($rficdtc) 
        return <error rule="SD1319" dataset="{data($name)}" variable="{data($stdtcname)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">{data($stdtcname)}={data($stdtc)} is before DM.RFICDTC={data($rficdtc)} in dataset {data($name)}</error>		
	
	