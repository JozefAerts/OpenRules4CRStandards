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

(: When ECOCCUR = 'N' then ECDOSE = null :)
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
(: get the EC dataset(s) definition :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Domain='EC' or starts-with(@Name,'EC')]
    let $name := $itemgroupdef/@Name
    (: get the dataset itself :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of ECOCCUR, ECDOSTXT and ECDOSE :)
    let $ecoccuroid := (
        for $a in $definedoc//odm:ItemDef[@Name='ECOCCUR']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (:  :)
    let $ecdoseoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ECDOSE']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get all the records in the dataset for which ECOCCUR = 'N' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ecoccuroid and @Value='N']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ECDOSE (as text) :)
        let $dose := $record/odm:ItemData[@ItemOID=$ecdoseoid]/@Value
        (: When ECOCCUR = 'N' then ECDOSE = null or >0 :)
        where number($dose)=0 or number($dose)<0 (: dose must either be null or >0 :)
        return 
            <error rule="CG0101" dataset="{data($name)}" variable="ECDOSE" rulelastupdate="2020-08-04" recordnumber="{$recnum}">ECDOSE={data($dose)} is expected to be null as ECOCCUR='N'</error>			
		
	