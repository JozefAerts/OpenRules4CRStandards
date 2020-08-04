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

(: Rule CG0244 TA,TV - ARM not in ('Screen Failure', 'Not Assigned', 'Unplanned Treatment', 'Not Treated') 
NOT applicable to SDTM-IG 3.3, there is a separate rule for this :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the TA and TV datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TA' or @Name='TV']
    let $name := $datasetdef/@Name
	let $datasetname := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc:= doc(concat($base,$datasetname))
    (: get the OID of ARM (planned arm name) :)
    let $armoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARM']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset for which 'ARM' is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$armoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARM :)
        let $arm := $record/odm:ItemData[@ItemOID=$armoid]/@Value
        (: ARM not in ('Screen Failure', 'Not Assigned', 'Unplanned Treatment', 'Not Treated') :)
        (: give an error when ARM has one of the above values :)
        where $arm='Screen Failure' or $arm='Not Assigned' or $arm='Unplanned Treatment' or $arm='Not Treated'
        return <error rule="CG0244" dataset="{data($name)}" variable="ARM" recordnumber="{data($recnum)}" rulelastupdate="2020-08-04">Value for planned ARM='{data($arm)}' is not allowed in dataset {data($name)}</error>			
		
	