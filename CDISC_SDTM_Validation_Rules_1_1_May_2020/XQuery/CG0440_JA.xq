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

(: When When TSPARMCD = 'PLANSUB' then TSVAL is integer and > 0  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion='2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdatasetdoc := (
	if($tsdatasetname) then doc(concat($base,$tsdatasetname))
	else ()
)
(: get the OID of the TSPARMCD variable and of the TSVAL variable :)
let $tsparmcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvaloid := (
    for $a in $definedoc//odm:ItemDef[@Name='TSVAL']/@OID 
    where $a = $definedoc//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get the record in the TS dataset that has TSPARMCD=PLANSUB :)
let $tsageminrecord := $tsdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='PLANSUB']] 
let $tsageminrecordnumber := $tsageminrecord/@data:ItemGroupDataSeq
(: and get the TSVAL value :)
let $tsvalvalue := $tsageminrecord/odm:ItemData[@ItemOID=$tsvaloid]/@Value
(: TSVAL must be an integer and larger then 0 :)
where $tsvalvalue and not($tsvalvalue castable as xs:integer) and xs:integer($tsvalvalue) > 0
return <error rule="CG0440" rulelastupdate="2020-08-04" dataset="TS" variable="TSVAL" recordnumber="{data($tsageminrecordnumber)}">Invalid TSVAL value for PLANSUB, value={data($tsvalvalue)} in dataset TS</error>				
		
	