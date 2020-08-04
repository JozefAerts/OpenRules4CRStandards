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

(: Rule CG0503: When MIDSDTC present in dataset, then MIDS present in dataset :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over all datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef
	let $name := $datasetdef/@Name
	(: get the OID of the MIDSDTC variable - if any :)
	let $midstdtcoid := (
        for $a in $definedoc//odm:ItemDef[@Name='MIDSDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
   	)
    (: get the OID of the MIDS variable - if any  :)
    let $midsoid := (
        for $a in $definedoc//odm:ItemDef[@Name='MIDS']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
   	)
   (: return an error when MIDSDTC is present, but but MIDS is not :)
 	where $midstdtcoid and not($midsoid)
    	return <error rule="CG0503" dataset="{data($name)}" rulelastupdate="2020-08-04">No MIDS variable is present although MIDSDTC is present</error>
	
	