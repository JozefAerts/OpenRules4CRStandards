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
		
(: Rule SE2316: 'Control Type' (TCNTRL) record must be populated in Trial Sets (TX) domain :)
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
(: let $base := 'SEND_3_0_PDS2014/' :)
(: let $define := 'define2-0-0_DS.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TS dataset :)
let $tsdataset := $definedoc//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := (
	if($defineversion='2.1') then $tsdataset/def21:leaf/@xlink:href
	else $tsdataset/def:leaf/@xlink:href
)
let $tsdoc := (
	if($tsdataset) then doc(concat($base,$tsdatasetname))
	else ()
)
(: get the OID of the TSPARMCD variable :)
let $tsparmcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: Check whether there is TSPARMCD=TCNTRL record :)
let $tsparmcdvalue := $tsdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='TCNTRL']]
where not($tsparmcdvalue)
return <error rule="SE2316" dataset="TS" variable="TSPARMCD" rulelastupdate="2020-06-25">No PARAMCD=TCNTRL record was found</error>

