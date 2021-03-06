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
	
(: Rule CG0371 - When IDVAR != null then IDVARVAL = value of variable = IDVAR in domain = RDOMAIN  :)
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
(: Get the CO, RELREC and SUPP-- datasets :)
let $datasets := $definedoc//odm:ItemGroupDef[@Name='RELREC' or starts-with(@Name,'CO') or starts-with(@Name,'SUPP')]
(: iterate over these datasets :)
for $dataset in $datasets
    (: Get the name and location :)
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: and take the OIDs of USUBJID, RDOMAIN, IDVAR and IDVARVAL :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $idvarvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and retrieve the values of RDOMAIN, USUBJID, IDVAR and IDVARVAL :)
        let $rdomainval := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        let $usubjidvalue := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        let $idvarvalue := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
        let $idvarvalvalue := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
        (: find the corresponding record in the parent domain, which can have splitted datasets :)
        (: IMPORTANT REMARK: @Domain is only required in the context of a regulatory submission - so we must look at the first characters of the name too :)
        let $parentdatasets := $definedoc//odm:ItemGroupDef[@Domain=$rdomainval or substring(@Name,1,2)=$rdomainval]
        (: in case of splitted datasets, $parentrecordcount gives e.g. 0 0 21 :)
        let $parentrecordcount := (
            for $parentdataset in $parentdatasets
                let $parentname := $parentdataset/@Name
				let $parentdatasetname := (
					if($defineversion='2.1') then $parentdataset/def21:leaf/@xlink:href
					else $parentdataset/def:leaf/@xlink:href
				)
                let $parentdatasetlocation := concat($base,$parentdatasetname)
                (: get the OID of USUBJID in the parent dataset  :)
                let $parentusubjidoid := (
                    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
                    where $a = $definedoc//odm:ItemGroupDef[@Name=$parentname]/odm:ItemRef/@ItemOID
                    return $a
                )
                (: get the OID of the identifying variable in the parent dataset :)
                let $parentidvaroid := (
                    for $a in $definedoc//odm:ItemDef[@Name=$idvarvalue]/@OID 
                    where $a = $definedoc//odm:ItemGroupDef[@Name=$parentname]/odm:ItemRef/@ItemOID
                    return $a
                )
                (: try to find the record in this dataset :)
                return 
                    (: case DM - no IDVAR or IDVARVAL :)
                    if($rdomainval = 'DM') then 
                        count(doc($parentdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$parentusubjidoid][@Value=$usubjidvalue]])
                    (: RDOMAIN is NOT DM - check on IDVAR/IDVARVAL :)
                    else (  
                        count(doc($parentdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$parentusubjidoid][@Value=$usubjidvalue] and odm:ItemData[@ItemOID=$parentidvaroid][@Value=$idvarvalvalue]] )  
                    )
        )
        let $parentrecordcountsummed := sum($parentrecordcount) (: sum the counts over the (splitted) datasets :)
        where $parentrecordcountsummed = 0  (: parent no records found at all :)
        return <error rule="CG0371" dataset="{data($name)}" variable="IDVARVAL" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">Invalid referenced record - Dataset={data($name)}: no parent records found in RDOMAIN={data($rdomainval)} for USUBJID={data($usubjidvalue)} with IDVAR='{data($idvarvalue)}' and IDVARVAL='{data($idvarvalvalue)}'</error>			
		
	