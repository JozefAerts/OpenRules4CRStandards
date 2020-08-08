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

(: Rule SD1039: --CAT value is redundant with other variable values - Value of Category (--CAT) should not be identical to that in Domain Abbreviation (DOMAIN); Reported Term (--TERM); Name of Measurement, Test, or Examination (--TESTCD); Name of Treatment (--TRT); Body System or Organ Class (--BODSYS) :)
(: Applicable to INTERVENTIONS, EVENTS, FINDINGS, TI :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml'  :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets in INTERVENTIONS, EVENTS, FINDINGS, TI :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][@Name='TI' or upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS']
    (: get the name of the dataset :)
    let $name := $datasetdef/@Name
    (: get the OID of --CAT - ATTENTION! Take care of --SCAT :)
    let $catoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'CAT') and string-length(@Name)=5]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
	let $catname := $definedoc//odm:ItemDef[@OID=$catoid]/@Name
    (: get the OIDs of Domain Abbreviation (DOMAIN); Reported Term (--TERM); Name of Measurement, Test, or Examination (--TESTCD); Name of Treatment (--TRT); Body System or Organ Class (--BODSYS) :)
    let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    let $termoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TERM')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    let $testcdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TESTCD')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    let $trtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TRT')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    let $bodsysoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BODSYS')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a
    )
    (: get the dataset location :)
    let $datasetloc := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the document itself :)
    let $datasetdoc := doc(concat($base,$datasetloc))
    (: iterate over all records that have --CAT populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$catoid]/@Value]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of the --CAT variable :)
        let $cat := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        (: get the values of DOMAIN, --TERM, --TESTCD, --TRT, --BODSYS
            (if any) :)
        let $domain := $record/odm:ItemData[@ItemOID=$domainoid]/@Value
        let $term := $record/odm:ItemData[@ItemOID=$termoid]/@Value
        let $testcd := $record/odm:ItemData[@ItemOID=$testcdoid]/@Value
        let $trt := $record/odm:ItemData[@ItemOID=$trtoid]/@Value
        let $bodsys := $record/odm:ItemData[@ItemOID=$bodsysoid]/@Value
        (: The value of --CAT may not be identical to any of DOMAIN, --TERM, --TESTCD, --TRT, --BODSYS :)
        where ($cat=$domain or $cat=$term or $cat=$testcd or $cat=$trt or $cat=$bodsys)	
		return <warning rule="SD1039" variable="{$catname}" dataset="{$name}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">The value of {data($catname)} is redundant. It is equal to one of DOMAIN, --TERM, --TESTCD, --TRT, --BODSYS</warning>
	
	