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

(: Rule SD1318: No records for subject found in DV domain for DS PROTOCOL VIOLATION - 
Subjects who has DSDECOD='PROTOCOL VIOLATION' records in Disposition (DS) domain should have supportive records with details in Protocol Deviations (DV) domain.
:)
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
let $define := 'define2-0-0-example-sdtm.xml'  :)
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
(: get the DV (Protocol Deviations) dataset(s) :)
for $dvdatasetdef in $definedoc//odm:ItemGroupDef[@Domain='DV']
    let $name := $dvdatasetdef/@Name
    (: get the dataset location and the document itself :)
    let $dvdatasetloc := (
		if($defineversion = '2.1') then $dvdatasetdef/def21:leaf/@xlink:href
		else $dvdatasetdef/def:leaf/@xlink:href
	)
    let $dvdatasetdoc := doc(concat($base,$dvdatasetloc))
    (: we need the OID of USUBJID in DV :)
    let $dvusubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $dvdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the DS dataset for which DSDECOD = 'PROTOCOL VIOLATION' :)
    for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dsdecodoid and @Value='PROTOCOL VIOLATION']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID value :)
        let $dsusubjid := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
        (: count the number of records in DV for this subject :)
        let $count := count($dvdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$dvusubjidoid]/@Value=$dsusubjid)
        (: there must be such at least one record in DV :)
        where $count = 0
        return <error rule="SD1318" variable="DSDECOD" dataset="{$name}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">No record was found in DV for subject with USUBJID='{data($dsusubjid)}' although there is a record in DS with DSDECOD='PROTOCOL DEVIATION'</error>				
	
	