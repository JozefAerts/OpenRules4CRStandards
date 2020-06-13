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

(: Rule CG0042: When AESCAN != 'Y' and AESCONG != 'Y' and AESDISAB != 'Y' and AESDTH != 'Y' and AESHOSP != 'Y' and AESLIFE != 'Y' and AESOD != 'Y' and AESMIE != 'Y' 
 then AESER = 'N'
:)
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

(: iterate over the AE datasets (for the case there is more than 1) :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Domain='AE' or starts-with(@Name,'AE')]
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OIDs of AESER, AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE :)
    let $aeseroid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESER']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aescanoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESCAN']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aescongoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESCONG']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a    
    )
    let $aesdisaboid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESDISAB']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aesdthoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESDTH']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aeshospoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESHOSP']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aeslifeoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESLIFE']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $aesmieoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AESMIE']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    (: iterate over all the records :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of AESER :)
        let $aeservalue := $record/odm:ItemData[@ItemOID=$aeseroid]/@Value
        (: get the values of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE (if any) :)
        let $aescanvalue := $record/odm:ItemData[@ItemOID=$aescanoid]/@Value
        let $aescongvalue := $record/odm:ItemData[@ItemOID=$aescongoid]/@Value
        let $aesdisabvalue := $record/odm:ItemData[@ItemOID=$aesdisaboid]/@Value
        let $aesdthvalue := $record/odm:ItemData[@ItemOID=$aesdthoid]/@Value
        let $aeshospvalue := $record/odm:ItemData[@ItemOID=$aeshospoid]/@Value
        let $aeslifevalue := $record/odm:ItemData[@ItemOID=$aeslifeoid]/@Value
        let $aesmievalue := $record/odm:ItemData[@ItemOID=$aesmieoid]/@Value
        (: when none of AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE and AESMIE has the value 'Y'
        then AESER must be 'N':)
        where $aescanvalue!='Y' and $aescongvalue!='Y' and $aesdisabvalue!='Y' and $aesdthvalue!='Y' and $aeshospvalue!='Y' and $aeslifevalue!='Y' and $aesmievalue!='Y' and not($aeservalue = 'N')
        return <error rule="CG0042" dataset="{data($name)}" variable="AESER" rulelastupdate="2020-06-11" recordnumber="{data($recnum)}">No qualifiers AESCAN, AESCONG, AESDISAB, AESDTH, AESHOSP, AESLIFE or AESMIE set to 'Y', when AE is Serious in dataset {data($datasetname)}</error>				
		
	