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

(: Rule CG0291 When TSVALNF = null then TSVAL not populated with values or synonyms of values in the ISO 21090 null flavor codelist (or other terms that can be represented as null flavors)  :)
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
(: the list of allowed null flavor values - ISO21090 :)
let $nfvalues := ('NI','OTH','NINF','PINF','UNK','ASKU','NAV','NASK','TRC','MSK','NA','QS')
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVAL and TSVALNF variables :)
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
    (: get the dataset :)
    let $datasetlocation := $itemgroup/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset for which TSVALNF is null :)
    for $record in $datasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$tsvalnfoid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the TSVAL value :)
        let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
        (: TSVAL is not allowed to come out of the list of ISO-21090 null flavors :)
        where functx:is-value-in-sequence($tsval,$nfvalues)
        return <error rule="CG0291" dataset="TS" variable="TSVAL" recordnumber="{data($recnum)}" rulelastupdate="2017-03-01">As TSVALNF=null, TSVAL={data($tsval)} is not allowed to come out of the list of ISO-21090 null flavors ({data($nfvalues)}</error>			
		
		