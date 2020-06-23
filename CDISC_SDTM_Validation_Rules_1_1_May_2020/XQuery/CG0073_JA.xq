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

(: Rule CG0073 When DSCAT != 'DISPOSTION EVENT' then EPOCH = null :)
(: Unclear whether also applicable to SDTMIG v.3.3 :)
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
(: and the location of the DS dataset :)
let $dsdatasetlocation := $dsitemgroupdef/def:leaf/@xlink:href
let $dsdatasetdoc := doc(concat($base,$dsdatasetlocation))
(: get the OID of USUBJID and of DSCAT in DS :)
let $dscatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSCAT']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
let $dsusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: and of EPOCH in DS :)
let $dsepochoid := (
    for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
    where $a = $dsitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: Iterate over all records that have DSCAT='DISPOSITION EVENT' :)
for $record in $dsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dscatoid and not(@Value='DISPOSITION EVENT')]]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the USUBJID :)
    let $usubjid := $record/odm:ItemData[@ItemOID=$dsusubjidoid]/@Value
    (: and get the value of EPOCH :)
    let $epoch := $record/odm:ItemData[@ItemOID=$dsepochoid]/@Value
    (: EPOCH must be null :)
    where $epoch != ''
    return <error rule="CG0073" dataset="DS" rulelastupdate="2020-06-11" recordnumber="{data($recnum)}">DSCAT='DISPOSITION EVENT' but DSEPOCH is not null. DSEPOCH='{data($epoch)}' was found</error>		
		
	