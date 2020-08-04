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

(: Rule CG0266 - When TSVCDVER != null then TSVCDREF != null :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all TS datasets - there should only be one :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TS']
    let $name := $datasetdef/@Name
	let $datasetname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetlocation:= concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OIDs of TSVCDVER and TSVCDREF :)
    let $tsvcdveroid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVCDVER']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $tsvcdrefoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVCDREF']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records for which TSVCDVER != null :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsvcdveroid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of TSVCDVER :)
        let $tsvcdver := $record/odm:ItemData[@ItemOID=$tsvcdveroid]/@Value
        (: and the value of TSVCDREF (if any) :)
        let $tsvcdref := $record/odm:ItemData[@ItemOID=$tsvcdrefoid]/@Value
        (: TSVCDREF may not be null :)
        where not($tsvcdref) 
        return <error rule="CG0266" dataset="{data($name)}" variable="TSVCDREF" rulelastupdate="2020-08-04">TSVCDVER='{data($tsvcdver)}' but TSVCDREF=null</error>			
		
	