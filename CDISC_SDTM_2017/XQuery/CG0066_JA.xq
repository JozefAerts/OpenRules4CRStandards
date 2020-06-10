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

(: Rule CG0066: When DSCAT = 'PROTOCOL MILESTONE' then DSTERM = DSDECOD :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the DS dataset :)
let $dsitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='DS']
(: get the OIDs of DSCAT, DSTERM and DSDECOD :)
let $dscatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSCAT']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dstermoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSTERM']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsdecodoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the location of the dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Iterate over all records for which DSCAT='PROTOCOL MILESTONE' :)
for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and @Value='PROTOCOL MILESTONE']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of DSTERM and DSDECOD :)
    let $dstermvalue := $record/odm:ItemData[@ItemOID=$dstermoid]/@Value
    let $dsdecodvalue := $record/odm:ItemData[@ItemOID=$dsdecodoid]/@Value
    (: the value of DSTERM must be identical to the value of DSDECOD :)
    where not($dsdecodvalue=$dstermvalue)
    return <error rule="CG0066" variable="DSDECOD" dataset="DS" rulelastupdate="2017-02-06" recordnumber="{data($recnum)}">The value of DSDECOD is not identical to the value of DSTERM although the value of DSCAT='PROTOCOL MILESTONE'. Value found for DSDECOD='{data($dsdecodvalue)}', value found for DSTERM='{data($dstermvalue)}' </error>			
	