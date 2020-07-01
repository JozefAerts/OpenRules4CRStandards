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
	
(: Rule SD1040 - Redundancy in paired variables values:
Value of Subcategory (--SCAT) should not be  identical to that in Domain Abbreviation (DOMAIN); Reported Term (--TERM); Name of Measurement, Test, or Examination (--TESTCD); Name of Treatment (--TRT); Body System or Organ Class (--BODSYS)
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

(: iterate over all datasets that have a --SCAT variable in the interventions, events findings domains and the TI dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Name='TI']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OID of the --SCAT variable (if any) :)
    let $scatoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'SCAT') and string-length(@Name)=6]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $scatname := concat($name,'SCAT')
    (: similarly, get the OIDs of DOMAIN, TERM, TESTCD, TRT, BODSYS :)
    let $domainoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $termoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TERM') and string-length(@Name)=6]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a    
    )
    let $testcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TESTCD') and string-length(@Name)=8]/@OID 
            where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
            return $a    
    )
    let $trtoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'TRT') and string-length(@Name)=5]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a    
    )
    let $bodsysoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'BODSYS') and string-length(@Name)=7]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a    
    )
    (: iterate over all the records that do have a value for --CAT :)
    for $record in doc($datasetlocation)[$scatoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$scatoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $scatvalue := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        (: and get the values of the DOMAIN, TERM, TESTCD, TRT, BODSYS variables (when present) :)
        let $domainvalue := $record/odm:ItemData[@ItemOID=$domainoid]/@Value
        let $termvalue := $record/odm:ItemData[@ItemOID=$termoid]/@Value
        let $testcdvalue := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
        let $trtvalue := $record/odm:ItemData[@ItemOID=$trtoid]/@Value
        let $bodsysvalue := $record/odm:ItemData[@ItemOID=$bodsysoid]/@Value
        (: we do already have selected on the presence of a value for the CAT variable,
        now compare it with the values of the DOMAIN, TERM, TESTCD, TRT, BODSYS variables
        (when present) :)
        where $scatvalue=$domainvalue or $scatvalue=$termvalue or $scatvalue=$testcdvalue or $scatvalue=$trtvalue or $scatvalue=$bodsysvalue
        return <warning rule="SD1040" rulelastupdate="2019-08-30" recordnumber="{data($recnum)}">Redundancy in paired variables values for {data($scatname)} with value={data($scatvalue)}.</warning>
