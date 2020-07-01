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
	
(: Rule SD1122 - Missing value for --STRESN: Standardized Result in Numeric Format (--STRESN) variable value should be populated, when Standardized Result in Character Format (--STRESC) variable value represents a numeric value
:)
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

(: Iterate over all FINDINGS domains :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: and get the OIDs of the STRESC and STRESN variables :)
    let $strescoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRESC')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a 
    )
    let $strescname := doc(concat($base,$define))//odm:ItemDef[@OID=$strescoid]/@Name
    let $stresnoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'STRESN')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a     
    )
    let $stresnname := doc(concat($base,$define))//odm:ItemDef[@OID=$stresnoid]/@Name
    (: now iterate over all records in the dataset that DO have an STRESC :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$strescoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values for STRESC and ORRES :)
        let $strescvalue := $record/odm:ItemData[@ItemOID=$strescoid]/@Value 
        let $stresnvalue := $record/odm:ItemData[@ItemOID=$stresnoid]/@Value
        (: we already selected on the presence of ORRES, check whether STRESN is present AND represents a numeric value :)
         where not($stresnvalue) and $strescvalue castable as xs:double
        return <warning rule="SD1122" dataset="{data($name)}" variable="{data($stresnname)}" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">Missing value for {data($stresnname)}, when {data($strescname)} value={data($strescvalue)} is provided and represents a numeric value in dataset {data($datasetname)}</warning>	