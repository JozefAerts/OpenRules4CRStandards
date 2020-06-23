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

(: Rule CG0570: ARM not in ('Screen Failure', 'Not Assigned', 'Unplanned Treatment', 'Not Treated') 
Applicable to DM, TA, TV :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over DM, TA and TV :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='DM' or @Name='TA' or @Name='TV']
    let $name := $itemgroupdef/@Name
    (: get the OID of ARM :)
    let $armoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARM (when any) :)
        let $arm := $record/odm:ItemData[@ItemOID=$armoid]/@Value
        (: give an error when ARM is either 'Screen Failure', 'Not Assigned', 'Unplanned Treatment', 'Not Treated' :)
        where $arm='Screen Failure' or $arm='Not Assigned' or $arm='Unplanned Treatment' or $arm='Not Treated'
        return <error rule="CG0570" dataset="{data($name)}" variable="ARM" recordnumber="{data($recnum)}" rulelastupdate="2020-06-22">Value '{data($arm)}' is not allowed for variable ARM</error>								
	
	