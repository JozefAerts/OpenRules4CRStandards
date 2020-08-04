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

(: Rule CG0336 - --CAT != Domain Name :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: get the Domain either from the dataset name or the Domain attribute :)
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2)
    )
    (: we need the OID of --CAT (if any) and the complete name :)
    let $catoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'CAT') and string-length(@Name)=5]/@OID  (: to exclude --SCAT :)
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $catname := $definedoc//odm:ItemDef[@OID=$catoid]/@Name
    (: get the dataset location and document :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records for which --CAT is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$catoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --CAT :)
        let $cat := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        (: the value of --CAT may not be equal to the domain name :)
        where $cat=$domain
        return <error rule="CG0336" dataset="{data($name)}" variable="{data($catname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of {data($catname)}='{data($cat)}' is not allowed to be equal to the name of the domain '{data($domain)}'</error>			
		
	