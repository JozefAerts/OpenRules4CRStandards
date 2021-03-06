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

(: Rule SD1312 - Missing PCLAS Trial Summary Parameter:
'Pharmacological Class of Investigational Therapy' (PCLAS) record must be populated in Trial Summay (TS) domain, when study type is 'INTERVENTIONAL' and if Intervention Type (INTTYPE) is one for which pharmacological class is applicable. It is expected for SDTM IG v3.1.2 data and required for data in all more recent SDTM versions.
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion = '2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD and TSVAL :)
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
(: get the record with TSPARMCD=STYPE :)
let $styperecord := doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='STYPE']]
(: and the value for TSVAL of the record with TSPARMCD=STYPE :)
let $stypevalue := $styperecord/odm:ItemData[@ItemOID=$tsvaloid]/@Value
(: get the record for which TSPARMCD=PCLASS :)
let $pclassrecord := doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='PCLASS']]
(: and the value :)
let $pclassvalue := $pclassrecord/odm:ItemData[@ItemOID=$tsvaloid]/@Value
(: when STYPE=INTERVENTIONAL, there MUST be a TSVAL for TSPARMCD=PCLASS :)
where $stypevalue='INTERVENTIONAL' and (not($pclassrecord) or not($pclassvalue))
return <error rule="SD1312" dataset="TS" rulelastupdate="2020-08-08">Missing PCLAS Trial Summary Parameter, although there is a record with TSPARMCD=STYPE and TSVAL=INTERVENTIONAL</error>
