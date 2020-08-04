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

(: Rule CG0348 - When --STAT = null or --DRVFL != 'Y' then --ORRES != null :)
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
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='FINDINGS'][@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    let $domainname := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else substring($name,1,2)
    )
    (: we need the OID of --ORRES (if any) and the complete name :)
    let $orresoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ORRES')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and its full name :)
    let $orresname := $definedoc//odm:ItemDef[@OID=$orresoid]/@Name
    (: and also for --STAT and --DRVFL :)
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $statname :=  concat($domainname,'STAT')  (: as xxSTAT is permissible, so may be completely absent :)
    let $drvfloid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DRVFL')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $drvflname := concat($domainname,'DRVFL')
    (: get the location of the dataset and the document itself :)
	let $datasetlocation := (
		if($defineversion='2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset for which --STAT is null (but present) or --DRVFL != 'Y' (but --DRVFL present) :)
    for $record in $datasetdoc[$orresoid and ($statoid or $drvfloid)]//odm:ItemGroupData[$statoid and (not(odm:ItemData[@ItemOID=$statoid])) or ($drvfloid and not(odm:ItemData[@ItemOID=$drvfloid]/@Value='Y'))]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of --DRVFL (we already know that --STAT is null) :)
        let $drvfl := $record/odm:ItemData[@ItemOID=$drvfloid]/@Value
        (: and the value of --ORRES (if any) :)
        let $orres := $record/odm:ItemData[@ItemOID=$orresoid]/@Value
        (: --ORRES may not be null :)
        where not($orres)
        return <error rule="CG0348" dataset="{data($name)}" variable="{data($orresname)}" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value of {data($orresname)} may not be null when {data($statname)}=NULL or {data($drvflname)}!='Y'</error>												
		
	