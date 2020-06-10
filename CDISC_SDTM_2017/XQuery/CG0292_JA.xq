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

(: Rule CG0292 - When TSPARMCD equals one of the values in the list of Trial Summary Codes in Appendix C1 and TSVALNF is null then TSVAL != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: A list with the TSPARMCD from SDTM-IG 3.2 Appendix C1 :)
let $tsparmcds := ("ADDON","AGEMAX","AGEMIN","LENGTH","PLANSUB","RANDOM","SEXPOP","STOPRULE","TBLIND","TCNTRL","TDIGRP",
"TINDTP","TITLE","TPHASE","TTYPE","CURTRT","OBJPRIM","OBJSEC","SPONSOR","COMPTRT","INDIC","TRT","RANDQT","STRATFCT",
"REGID","OUTMSPRI","OUTMSSEC","OUTMSEXP","PCLAS","FCNTRY","ADAPT","DCUTDTC","DCUTDESC","INTMODEL","NARMS","STYPE",
"INTTYPE","SSTDTC","SENDTC","ACTSUB","HLTSUBJI","SDMDUR","CRMDUR" )
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVAL, TSVALNF and TSPARMCD variables :)
    let $tsvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsvalnfoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVALNF']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsparmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset :)
    let $datasetname := $itemgroup//def:leaf/@xlink:href
    let $dataset := concat($base,$datasetname)
    let $datasetdoc := doc($dataset)
    (: iterate over all the records in the dataset for which TSPARMCD is one of the list of Appendix C1 of the SDTM-IG :)
    for $record in $datasetdoc//odm:ItemGroupData[functx:is-value-in-sequence(odm:ItemData[@ItemOID=$tsparmcdoid]/@Value,$tsparmcds)]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of the current TSPARMCD :)
        let $tsparmcd := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
        (: get the value of TSVALNF and of TSVAL :)
        let $tsvalnf := $record/odm:ItemData[@ItemOID=$tsvalnfoid]/@Value
        let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
        (: when TSVALNF is null then TSVAL != null :)
        where not($tsvalnf) and not($tsval)  (: Error when TSVAL is null and TSVAL is null :)
        return <error rule="CG0292" dataset="TS" variable="TSVAL" recordnumber="{data($recnum)}" rulelastupdate="2017-03-01">As TSPARMCD={data($tsparmcd)} comes out of the list from SDTM-IG 3.2 Appendix C1 and TSVALNF=null, TSVAL is not allowed to be null</error>						
		
		