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

(: Rule SD1279 - ECDOSTXT may not be null when ECDOSE is null and ECOCCUR does not equal 'N' :)
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
(: get the EC dataset :)
let $ecdataset := $definedoc//odm:ItemGroupDef[@Name='EC']
let $ecdatasetname := (
	if($defineversion = '2.1') then $ecdataset/def21:leaf/@xlink:href
	else $ecdataset/def:leaf/@xlink:href
)
let $ecdatasetdoc := doc(concat($base,$ecdatasetname))
(: get the OID of ECDOSE, ECOCCUR and ECDOSTXT :)
let $ecdoseoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ECDOSE']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Domain='EC' or @Name='EC']/odm:ItemRef/@ItemOID
    return $a
)
let $ecoccuroid := (
    for $a in $definedoc//odm:ItemDef[@Name='ECOCCUR']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Domain='EC' or @Name='EC']/odm:ItemRef/@ItemOID
    return $a
)
let $ecdostxtoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ECDOSTXT']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Domain='EC' or @Name='EC']/odm:ItemRef/@ItemOID
    return $a
)
(: iterate over all the records in the EC for which ECDOSE = null and ECOCCUR != 'N' :)
for $record in $ecdatasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$ecdoseoid]) and not(odm:ItemData[@ItemOID=$ecoccuroid]/@Value = 'N')]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of ECDOSTXT :)
    let $ecdostxt := $record/odm:ItemData[@ItemOID=$ecdostxtoid]/@Value
    (: ECDOSTXT may not be null :)
    where not($ecdostxt) or string-length($ecdostxt)=0
    return <error rule="SD1279" dataset="EC" variable="ECDOSTXT" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">ECDOSTXT must be populated when ECDOSE=null</error>							

	