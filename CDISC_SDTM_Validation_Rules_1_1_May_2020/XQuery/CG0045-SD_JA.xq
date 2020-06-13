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

(: Rule CG0045: When --ENTPT != null then --ENRTPT != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/'
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'LB' :)

(: iterate over all the datasets :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: get the OIDs of the ENTPT and ENRTPT variables (if any) :)
    let $entptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $entptname := doc(concat($base,$define))//odm:ItemDef[@OID=$entptoid]/@Name
    let $enrtptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := doc(concat($base,$define))//odm:ItemDef[@OID=$enrtptoid]/@Name
    (: iterate over all the records in the dataset for which there is a ENTPT data point :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData/@ItemOID=$entptoid]
    let $recnum := $record/@data:ItemGroupDataSeq
        (: and check whether there is ENRTPT data point :)
        (: When --ENTPT != null then --ENRTPT != null :)
        let $entptvalue := $record/odm:ItemData[@ItemOID=$entptoid]/@Value
        let $enrtptvalue := $record/odm:ItemData[@ItemOID=$enrtptoid]/@Value
        where not($enrtptvalue)
        return <error rule="CG0045" rulelastupdate="2020-06-09" dataset="{data($name)}" variable="{data($enrtptname)}" recordnumber="{data($recnum)}">Missing value for {data($enrtptname)}, when {data($entptname)} is populated (not null), value = {data($entptvalue)}</error>				
		
	