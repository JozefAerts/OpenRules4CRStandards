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

(: Rule SD1316: Missing 'DEATH' record for subject in DS domain - All subjects who have Death records (SSSTRESC = 'DEAD') in Survival Status (SS) domain should also have death records (DSDECOD='DEATH') in Disposition (DS) domain :)
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
(: get the DS dataset :)
let $dsdatasetdef := $definedoc//odm:ItemGroupDef[@Name='DS' or @Domain='DS']
let $name := $dsdatasetdef/@Name (: for the ultimate case of DS splitted datasets :)
(: get the location and the dataset document itself :)
let $dsdatasetlocation := (
	if($defineversion = '2.1') then $dsdatasetdef/def21:leaf/@xlink:href
	else $dsdatasetdef/def:leaf/@xlink:href
)
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: get the OID of USUBJID and DSDECOD :)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsdatasetdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsdatasetdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the SS (Survival Status) dataset(s) :)
for $ssdatasetdef in $definedoc//odm:ItemGroupDef[@Domain='SS']
    let $ssname := $ssdatasetdef/@Name
    (: get the dataset location and the document itself :)
    let $ssdatasetloc := (
		if($defineversion = '2.1') then $ssdatasetdef/def21:leaf/@xlink:href
		else $ssdatasetdef/def:leaf/@xlink:href
	)
    let $ssdatasetdoc := doc(concat($base,$ssdatasetloc))
    (: we need the OID of USUBJID and SSSTRESC in SS :)
    let $ssusubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $ssdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $ssstrescoid := (
        for $a in $definedoc//odm:ItemDef[@Name='SSSTRESC']/@OID 
        where $a = $ssdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the SS dataset for which SSSTRESC = 'DEAD' :)
    for $record in $ssdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ssstrescoid and @Value='DEAD']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $ssusubjid := $record/odm:ItemData[@ItemOID=$ssusubjidoid]/@Value
        (: count the number of records in DS for which DSDECOD='DEATH' :)
        let $count := count($dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$ssusubjidoid and @Value=$ssusubjid] and odm:ItemData[@ItemOID=$dsdecodoid and @Value='DEATH']])
        (: there must be such a record :)
        where $count = 0
        return <error rule="SD1316" variable="SSSTRESC" dataset="{$ssname}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">No record was found in DS with DSDECOD='DEATH' for the record in dataset {data($ssname)} with SSSTRESC='DEAD' for subject with USUBJID='{data($ssusubjid)}'</error>				
	
	