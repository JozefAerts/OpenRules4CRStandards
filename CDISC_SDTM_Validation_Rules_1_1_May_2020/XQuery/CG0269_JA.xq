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

(: Rule CG0269 - When TSPARMCD = 'ADDON' and TSVAL != null then TSVAL in ('N','Y') :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all TS datasets (there should be only one) :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='TS']
    (: Get the OID for the TSVAL and TSPARMCD variables :)
    let $tsvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsparmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
        return $a
    )
	let $datasetname := (
		if($defineversion='2.1') then $itemgroup//def21:leaf/@xlink:href
		else $itemgroup//def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    let $datasetdoc := doc($dataset)
    (: iterate over all the records within the TS dataset for which TSPARMCD='ADDON' TSVAL!=null.
    Normally, there should be only be 1 such record :)
   for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvaloid] and odm:ItemData[@ItemOID=$tsparmcdoid and @Value='ADDON']]
        (: get the record number :)
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the TSVAL :)
        let $tsval := $record/odm:ItemData[@ItemOID=$tsvaloid]/@Value
        (: TSVAL must be one of 'Y' or 'N' :)
        where not($tsval='Y' or $tsval='N')
        return <error rule="CG0269" dataset="TS" variable="TSVAL" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">TSVAL='{data($tsval)}' for TSPARMCD='ADDON' is expected to be in ('N','Y')</error>			
		
	