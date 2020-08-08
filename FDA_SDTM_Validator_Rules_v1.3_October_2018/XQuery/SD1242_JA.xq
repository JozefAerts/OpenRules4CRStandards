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

(: Rule SD1242 - Inconsistent value for --BODSYS within --BDSYCD :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over the EVENTS and INTERVENTIONS datasets :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='AE' or @Domain='AE' or @Name='MH' or @Domain='MH' or @Name='CE' or @Domain='CE']
    let $name := $itemgroupdef/@Name
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetlocation := concat($base,$datasetname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OID of --BODSYS and of --BDSYCD :)
    let $bdsycdoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BDSYCD')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $bdsycdname := $definedoc//odm:ItemDef[@OID=$bdsycdoid]/@Name
    let $bodsysoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'BODSYS')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $bodsysname := $definedoc//odm:ItemDef[@OID=$bodsysoid]/@Name
    (: group all the records by --BDSYCD value: all the records in the group will have the same value for --BODSYS :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData
        group by 
        $b := $record/odm:ItemData[@ItemOID=$bdsycdoid]/@Value
        return element group {  
            $record
        }
    )
    (: iterate over all groups - each having the same value of --BDSYCD for all records within the group :)
    for $group in $orderedrecords[$bdsycdoid and $bodsysoid]
        (: get the value of --BDSYCD from the first record only :)
        let $bdsycd := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$bdsycdoid]/@Value
        (: get the first value of --BODSYS :)
        let $bodsys1 := $group/odm:ItemGroupData[1]/odm:ItemData[@ItemOID=$bodsysoid]/@Value
        let $recnum1 := $group/odm:ItemGroupData[1]/@data:ItemGroupDataSeq
        (: return <test>{data($bodsys)} - {data($bodsys)}</test> :)
        (: iterate over all other records in the same group, they have the same value for --BDSYCD,
        and must also have the same value for --BODSYS :)
        for $record in $group/odm:ItemGroupData[position()>1]
            let $recnum2 := $record/@data:ItemGroupDataSeq
            (: get the value of --BODSYS :)
            let $bodsys2 := $record/odm:ItemData[@ItemOID=$bodsysoid]/@Value
            (: the two --BODSYS values must be equal, except when they are null :)
            where $bdsycd!='' and $bodsys1!='' and $bodsys2!='' and not($bodsys1 = $bodsys2)
            return <error rule="SD1242" rulelastupdate="2020-08-08" dataset="{data($name)}" variable="{data($bodsysname)}" recordnumber="{data($recnum2)}">Combination of {data($bdsycdname)} and {data($bodsysname)} in dataset {data($datasetname)} is inconsistent: 
                record {data($recnum1)}: {data($bdsycdname)}='{data($bdsycd)}' - {data($bodsysname)}='{data($bodsys1)}', 
                record {data($recnum2)}: {data($bdsycdname)}='{data($bdsycd)}' - {data($bodsysname)}='{data($bodsys2)}', , 
            </error>				
	
	