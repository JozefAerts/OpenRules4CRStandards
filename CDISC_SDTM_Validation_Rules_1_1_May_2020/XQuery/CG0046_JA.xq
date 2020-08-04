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

(: Rule CG0046: When --ENRTPT != null then --ENTPT != null :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets :)
for $dataset in $definedoc//odm:ItemGroupDef
    let $name := $dataset/@Name
	let $dsname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
	let $datasetdoc := (
		if($dsname) then doc(concat($base,$dsname))
		else ()
	)
    (: get the OIDs of the ENTPT and ENRTPT variables (if any) :)
    let $entptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENTPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $entptname := $definedoc//odm:ItemDef[@OID=$entptoid]/@Name
    let $enrtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := $datasetdoc//odm:ItemDef[@OID=$enrtptoid]/@Name
    (: iterate over all the records in the dataset for which there is a ENRTPT data point :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData/@ItemOID=$enrtptoid]
		let $recnum := $record/@data:ItemGroupDataSeq
		(: and check whether there is ENTPT data point :)
		let $entptvalue := $record/odm:ItemData[@ItemOID=$entptoid]/@Value
		let $enrtptvalue := $record/odm:ItemData[@ItemOID=$enrtptoid]/@Value
		where not($entptvalue)
		return <error rule="CG0046" dataset="{data($name)}" rulelastupdate="2020-08-04" variable="{data($entptname)}" recordnumber="{data($recnum)}">Missing value for {data($entptname)}, when {data($enrtptname)} is populated (not null), value = {data($enrtptvalue)}</error>	
	
	