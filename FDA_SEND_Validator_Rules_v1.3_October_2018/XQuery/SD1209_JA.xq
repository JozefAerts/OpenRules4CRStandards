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

(: Rule SD1209: Missing value for RFXENDTC, when RFXSTDTC is provided - Value for Date/Time of Last Study Treatment (RFXENDTC) variable must be populated, when Date/Time of First Study Treatment (RFXSTDTC) variable value is provided. 
Only applies to SENDIG 3.1, not to 3.0  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the location of the DM dataset :)
let $dmdatasetdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
let $dmdatasetlocation := $dmdatasetdef/def:leaf/@xlink:href
(: Get the OID of the RFXENDTC and RFXSTDTC variables :)
let $rfxendtcoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RFXENDTC']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a  
)
let $rfxstdtcoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='RFXSTDTC']/@OID 
        where $a = $dmdatasetdef/odm:ItemRef/@ItemOID
        return $a    
)
(: iterate over all the records in the DM dataset that have RFXSTDTC populated :)
for $record in doc(concat($base,$dmdatasetlocation))//odm:ItemGroupData[odm:ItemData[@ItemOID=$rfxstdtcoid]/@Value]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: give an warning when RFXENDTC is not populated :)
    where not($record/odm:ItemData[@ItemOID=$rfxendtcoid])
    return <warning rule="SD1209" dataset="DM" rulelastupdate="2020-06-25" recordnumber="{data($recnum)}" variable="RFXENDTC">RFXENDTC is not populated although RFXSTDTC is populated</warning>	

