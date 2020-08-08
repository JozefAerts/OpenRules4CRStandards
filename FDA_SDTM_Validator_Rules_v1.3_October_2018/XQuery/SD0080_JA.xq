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
	
(: Rule SD0080 - AE start date is after the latest Disposition date:
Start Date/Time of Adverse Event (AESTDTC) should be less than or equal to the Start Date/Time of the latest Disposition Event (DSSTDTC) :)
(: TODO: extensive testing - can we make this faster? DS is queried (too) many times :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: get the location of the DS dataset and the OID for the DSSTDTC and USUBJID attributes :)
let $dsdataset := $definedoc//odm:ItemGroupDef[@Name='DS']
let $dsdatasetname := (
	if($defineversion = '2.1') then $dsdataset/def21:leaf/@xlink:href
	else $dsdataset/def:leaf/@xlink:href
)
let $dsdatasetlocation := concat($base,$dsdatasetname)
let $dsstdtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
    return $a
)
(: Get the AE dataset(s) :)
for $aedataset in $definedoc//odm:ItemGroupDef[@Domain='AE']
    let $aename := $aedataset/@Name
    let $aedatasetname := (
		if($defineversion = '2.1') then $aedataset/def21:leaf/@xlink:href
		else $aedataset/def:leaf/@xlink:href
	)
    let $aedatasetlocation := concat($base,$aedatasetname)
    (: and get the OID of AESTDC and USUBJID :)
    let $aestdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aeusubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the AE dataset(s) that have AESTDTC populated :)
    for $record in doc($aedatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$aestdtcoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of AESTDTC :)
        let $aestdtcvalue := $record/odm:ItemData[@ItemOID=$aestdtcoid]/@Value
        let $aeusubjidvalue := $record/odm:ItemData[@ItemOID=$aeusubjidoid]/@Value
        (: now get the latest (maximal) value DSSTDTC in the DS dataset for this subject :)
        let $dssdtcvalues := doc($dsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsusubjidoid and @Value=$aeusubjidvalue]]/odm:ItemData[@ItemOID=$dsstdtcoid]/@Value
        (: get the latest DSSTDTC date :)
        let $latestdate := max(for $date in $dssdtcvalues return xs:date($date))
        (: AESTDTC must be BEFORE the latest DSSTDTC :)
        where $aestdtcvalue and xs:date($latestdate) <= xs:date($aestdtcvalue) 
        return <error rule="SD0080" dataset="AE" variable="AESTDTC" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">AE start date, value={data($aestdtcvalue)} is after the latest Disposition date, value={data($latestdate)}</error>
