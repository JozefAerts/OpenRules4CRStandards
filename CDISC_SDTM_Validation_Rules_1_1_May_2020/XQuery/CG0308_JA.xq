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

(: Rule CG0308 - DOMAIN value length = 2, except for AP,RELREC
The rule is not 100% clear: does it apply to @Domain in the define.xml, or do DOMAIN/RDOMAIN values in the datasets themselves?
We implement it here for DOMAIN (but not for RDOMAIN) in non-AP, non-RELREC datasets.
Be aware that this assumes that RELREC and SUPPAP never reference AP records. 
Does this however also assume that there are no APxx records in CO? :)
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
(: iterate over all datasets definitions, except for AP, RELREC and SUPPAP :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[not(@Name='AP') and not(@Name='RELREC') and not(@Name='SUPPAP')]
    let $name := $itemgroupdef/@Name
    (: In each of the datasets, get the OID of the DOMAIN (when there is one) variable :)
    let $domainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DOMAIN']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset  :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: return over all the records that have a value for DOMAIN (this should essentially be all of them?) :)
	(: TODO? get the distinct values first - would that be faster? :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$domainoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of DOMAIN (if any) :)
        let $domainvalue := $record/odm:ItemData[@ItemOID=$domainoid]/@Value
        (: the length of the value must be exactly 2 :)
        where string-length($domainvalue)!=2
        return <error rule="CG0308" dataset="{data($name)}" variable="DOMAIN" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">The value for DOMAIN in the dataset does not consist of exactly 2 characters: DOMAIN='{data($domainvalue)}' was found</error>							
		
	