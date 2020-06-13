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

(: Rule CG0065: When DSTERM='COMPLETED' then DSDECOD='COMPLETED' :)
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
(: get the OIDs of DSTERM and DSDECOD :)
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
(: get the dataset location :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: Iterate over all records for which DSTERM='COMPLETED' :)
for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dstermoid and @Value='COMPLETED']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of DSDECOD :)
    let $dsdecodvalue := $record/odm:ItemData[@ItemOID=$dsdecodoid]/@Value
    (: the value of DSDECOD must be 'COMPLETED' :)
    where not($dsdecodvalue='COMPLETED')
    return <error rule="CG0065" variable="DSDECOD" dataset="DS" rulelastupdate="2020-06-11" recordnumber="{data($recnum)}">The value of DSDECOD is not 'COMPLETED' although the value of DSTERM='COMPLETED'. Value found for DSDECOD='{data($dsdecodvalue)}'</error>			
		
	