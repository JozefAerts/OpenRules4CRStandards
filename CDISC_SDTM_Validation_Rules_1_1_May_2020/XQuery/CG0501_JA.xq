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

(: Rule CG0501: When MIDS present in dataset, then TM must exist :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the TM dataset definition, if it exists :)
let $tmdatasetdef := $definedoc//odm:ItemGroupDef[@Name='TM']
(: get its location, and the dataset itsels (when it exists) :)
let $tmdatasetlocation := $tmdatasetdef/def:leaf/@xlink:href
let $tmdatasetdoc := (
	if($tmdatasetlocation) then doc(concat($base,$tmdatasetlocation))
    else ()
)
(: Iterate over all other datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[not(@Name='TM')]
	let $name := $datasetdef/@Name
	(: get the OID of the MIDS variable - if any :)
	let $midsoid := (
        for $a in $definedoc//odm:ItemDef[@Name='MIDS']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
   	)
   (: return an error when MIDS is present, but TM has not been declared, 
   	or could not eb found :)
 	where $midsoid and (not($tmdatasetlocation) or not(doc-available($tmdatasetdoc)))
    	return <error rule="CG0501" dataset="{data($name)}" rulelastupdate="2020-06-19">No TM dataset was declared or found although dataset {data($name)} has a MIDS variable</error>	
	
	