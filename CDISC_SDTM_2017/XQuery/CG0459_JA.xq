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

(: Rule CG0459 - When TSVAL not populated with values or synonyms of values in the ISO 21090 null flavor codelist (or other terms that can be represented as null flavors) 
		then TSVALNF = null
	The only thing we can check here is where TSVAL is not populated with any of the ISO 21090 null flavors.
    We cannot check on "synonyms", that would require artificial intelligence.	
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
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
(: The ISO-21090 null flavors: :)
let $nullflavors := ('NI','INV','DER','OTH','NINF','PINF','UNC','MSK','NA','UNK','ASKU','NAV','NASK','NAVU','QS','TRC','NP')
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetdoc := doc(concat($base,$tsdatasetname))
(: get the OID of TSVAL and TSVALNF :)
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
(: iterate over all the records in the TS dataset where TSVAL is populated :)
for $record in $tsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvaloid]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TSVAL and of TSVALNF :)
    let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
    let $tsvalnf := $record/odm:ItemData[@ItemOID=$tsvalnfoid]/@Value
    (: When TSVAL not populated with values in the ISO 21090 null flavor codelist, then TSVALNF must be null:)
    where not(functx:is-value-in-sequence($tsval,$nullflavors)) and string-length($tsvalnf)>0
    return <error rule="CG0459" dataset="TS" variable="TSVALNF" rulelastupdate="2017-03-25" recordnumber="{data($recnum)}">TSVALNF='{data($tsvalnf)}' must be null as TSVAL='{data($tsval)}' is not an ISO-21090 null flavor</error>							
		
		