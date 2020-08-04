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

(: Rule CG0027: --SCAT and --CAT must have different values :)
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
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Applies to: all datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2) (: first 2 characters :)
    )
    (: get the dataset :)
    let $name := $itemgroupdef/@Name
    (: get the OIDs of --CAT and --SCAT :)
    let $catoid := (
        for $a in $definedoc//odm:ItemDef[substring(@Name,3)='CAT']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $scatoid := (
        for $a in $definedoc//odm:ItemDef[substring(@Name,3)='SCAT']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $catname := $definedoc//odm:ItemDef[@OID=$catoid]/@Name
    let $scatname := $definedoc//odm:ItemDef[@OID=$scatoid]/@Name
    (: get the dataset location and document :)
	let $datasetname := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: iterate over all rows in the dataset, 
    but only when there --CAT and --SCAT have been defined :)
    for $record in $datasetdoc//odm:ItemGroupData[$catoid  and $scatoid]
    	let $recnum := $record/@data:ItemGroupDataSeq
        let $catvalue := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        let $scatvalue := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        where $catvalue != '' and $scatvalue != '' and $catvalue=$scatvalue
        return <error rule="CG0027" dataset="{data($name)}" variable="{data($scatname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of {data($catname)} and {data($scatname)} are identical: '{data($catvalue)}'</error>	
	
	