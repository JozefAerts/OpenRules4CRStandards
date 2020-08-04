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

(: Rule CG0241 - When --TPT != null and --TPTNUM != null and --ELTM != null then --ELTM is the same value across records with the same values of DOMAIN, VISITNUM, --TPTREF, and --TPTNUM :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $datasetdef/@Name
	let $dsname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetlocation:= concat($base,$dsname)
    let $datasetdoc := doc($datasetlocation)
    (: and get the OIDs of --TPT, --TPTNUM and --ELTM :)
    let $tptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPT')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    let $tptname := $definedoc//odm:ItemDef[@OID=$tptoid]/@Name
    (: get the OID of --TPTNUM :)
    let $tptnumoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTNUM')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    let $tptnumname := $definedoc//odm:ItemDef[@OID=$tptnumoid]/@Name
    (: get the OID of --TPTREF :)
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name
    (: get the OID of --ELTM :)
    let $eltmoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    let $eltmname := $definedoc//odm:ItemDef[@OID=$eltmoid]/@Name
    (: get the OID of VISITNUM :)
    let $visitnumoid := (
        for $a in $definedoc//odm:ItemDef[@Name='VISITNUM']/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    (: --ELTM is the same value across records with the same values of DOMAIN, VISITNUM, --TPTREF, and --TPTNUM 
    So we need to group the records by the combination of DOMAIN, VISITNUM, --TPTREF, and --TPTNUM. 
    As all the records in one dataset have the same DOMAIN, it suffices to group by VISITNUM, --TPTREF, and --TPTNUM :)
    (: However, do exclude records for which --TPT = null or --TPTNUM = null or --ELTM = null :)
    let $orderedrecords := (
        for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tptoid] and odm:ItemData[@ItemOID=$tptnumoid] and odm:ItemData[@ItemOID=$eltmoid]]
            group by 
            $b := $record/odm:ItemData[@ItemOID=$visitnumoid]/@Value,
            $c := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value,
            $d := $record/odm:ItemData[@ItemOID=$tptnumoid]/@Value
            return element group {  
                $record
            }
        )  
    for $group in $orderedrecords   
        (: each group now has the same values of DOMAIN, VISITNUM, --TPTREF and --TPTNUM :)
        (: count the number of distinct values for --ELTM :)
        let $count := count(distinct-values($group/odm:ItemGroupData/odm:ItemData[@ItemOID=$eltmoid]/@Value))
        (: the number of distinct values of ELTM within each group must be exactly 1 :)
        where $count != 1
        return <error rule="CG0241" dataset="{data($name)}" variable="{data($eltmname)}" rulelastupdate="2020-08-04">Inconsistent value for {data($eltmname)} within group of DOMAIN/VISITNUM/{data($tptrefname)}/{data($tptnumname)} in dataset {data($datasetname)}. {data($count)} different {data($eltmname)} values were found for this group</error>				
		
	