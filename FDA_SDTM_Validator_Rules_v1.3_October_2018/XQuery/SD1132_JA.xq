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

(: Rule SD1132: Serious Event (AESER) variable value is expected to be 'Y', when either of Seriousness Criteria variables (AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE, AESMIE) has value 'Y' :)
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
(: Get the AE dataset(s) :)
for $aedataset in $definedoc//odm:ItemGroupDef[@Name='AE']
    let $aename := $aedataset/@Name
    let $aedatasetname := ( 
		if($defineversion = '2.1') then $aedataset/def21:leaf/@xlink:href
		else $aedataset/def:leaf/@xlink:href
	)
    let $aedatasetlocation := concat($base,$aedatasetname)
    (: and get the OID of the AESER and AESOD variables :)
    let $aeseroid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESER']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the OIDs of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE, AESMIE  :)
    let $aescanoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESCAN']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aescongoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESCONG']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aesdisaboid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESDISAB']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aesdthoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESDTH']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aeshospoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESHOSP']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aeslifeoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESLIFE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aesmieoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESMIE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records that have any of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE, AESMIE = 'Y' :)
    for $record in doc($aedatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$aescanoid and @Value='Y']
        or odm:ItemData[@ItemOID=$aescongoid and @Value='Y']
        or odm:ItemData[@ItemOID=$aesdisaboid and @Value='Y']
        or odm:ItemData[@ItemOID=$aesdthoid and @Value='Y']
        or odm:ItemData[@ItemOID=$aeshospoid and @Value='Y']
        or odm:ItemData[@ItemOID=$aeslifeoid and @Value='Y']
        or odm:ItemData[@ItemOID=$aesmieoid and @Value='Y'] ]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of AESER (if any) :)
        let $aeservalue := $record/odm:ItemData[@ItemOID=$aeseroid]/@Value
        (: AESER must have the value 'Y' :)
        (: where not($aeservalue) or not($aeservalue='Y') :)
        return <error rule="SD1132" dataset="AE" variable="AESER" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">AESER is not 'Y', when any of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE, AESMIE equals 'Y', value found for AESER={data($aeservalue)}</error>	
