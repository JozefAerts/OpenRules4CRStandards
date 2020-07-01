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
	
(: TODO: further testing - we need a good test file :)
(: Rule SD2019 - Invalid value for AGETXT:
Age Range (AGETXT) variable values should be populated with 'number-number' format
:)
(: Remark: regular expression was tested using: https://regex101.com/  :)
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

(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the AGETXT variable  :)
    let $agetxtoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AGETXT']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records where AGETXT is populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$agetxtoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of AGETXT :)
        let $agetxtvalue := $record/odm:ItemData[@ItemOID=$agetxtoid]/@Value
        where not(matches($agetxtvalue,'^[\d]*.[\d]*-[\d]*.[\d]*$'))
        return <warning rule="SD2019" dataset="DM" variable="AGETXT" rulelastupdate="2019-08-19" recordnumber="{data($recnum)}">Invalid value for AGETXT. '{data($agetxtvalue)}' was found</warning>
