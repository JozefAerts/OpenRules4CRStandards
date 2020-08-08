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
	
(: Rule SD0009 - No qualifiers set to 'Y', when AE is Serious:
When Serious Event (AESER) variable value is 'Y', then at least one of seriousness criteria variables is expected to have value 'Y' (Involves Cancer (AESCAN), Congenital Anomaly or Birth Defect (AESCONG), Persist or Signif Disability/Incapacity (AESDISAB), Results in Death (AESDTH), Requires or Prolongs Hospitalization (AESHOSP), Is Life Threatening (AESLIFE), or Other Medicaly Important Serious Event (AESMIE))
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
(: iterate over the AE datasets (for the case there is more than 1) :)
for $dataset in $definedoc//odm:ItemGroupDef[@Domain='AE']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OIDs of AESER, AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE :)
    let $aeseroid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESER']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aescanoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESCAN']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aescongoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESCONG']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a    
    )
    let $aesdisaboid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESDISAB']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aesdthoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESDTH']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aeshospoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESHOSP']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aeslifeoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESLIFE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aesmieoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESMIE']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all the records that have AESER=Y :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$aeseroid and @Value='Y']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the values of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE (if any) :)
        let $aescanvalue := $record/odm:ItemData[@ItemOID=$aescanoid]/@Value
        let $aescongvalue := $record/odm:ItemData[@ItemOID=$aescongoid]/@Value
        let $aesdisabvalue := $record/odm:ItemData[@ItemOID=$aesdisaboid]/@Value
        let $aesdthvalue := $record/odm:ItemData[@ItemOID=$aesdthoid]/@Value
        let $aeshospvalue := $record/odm:ItemData[@ItemOID=$aeshospoid]/@Value
        let $aeslifevalue := $record/odm:ItemData[@ItemOID=$aeslifeoid]/@Value
        let $aesmievalue := $record/odm:ItemData[@ItemOID=$aesmieoid]/@Value
        (: at least one of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE must have the value 'Y' :)
        where not($aescanvalue='Y' or $aescongvalue='Y' or $aesdisabvalue='Y' or $aesdthvalue='Y' or $aeshospvalue='Y' or $aeslifevalue='Y' or $aesmievalue='Y')
        return <error rule="SD0009" dataset="{data($name)}" variable="AESER" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">No qualifiers set to 'Y', when AE is Serious in dataset {data($datasetname)}</error>	
	