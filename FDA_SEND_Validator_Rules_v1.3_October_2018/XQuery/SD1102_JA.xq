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
	
(: TODO: not well tested yet :)       
(: Rule SD1102 - Missing --ENRTPT variable, when --ENTPT variable is present
End Reference to Reference Time Point (--ENRTPT) variable must be included into the domain, when End Relative Time Point (--ENTPT) variable is present
:) 
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
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all datasets except for DM :)
for $dataset in $definedoc//odm:ItemGroupDef[not(@Name='DM')]
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    (: Get the OID of the ENRTPT and ENTPT variable (when present) :)
    let $enrtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := concat($name,'ENRTPT')
    let $entptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENTPT')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $entptname := $definedoc//odm:ItemDef[@OID=$entptoid]/@Name
    (: when ENTPT is present, also ENRTPT must be present :)
    where $entptoid and not($enrtptoid)
    return <error rule="SD1102" variable="{data($enrtptname)}" dataset="{data($name)}" rulelastupdate="2019-08-21">Missing {data($enrtptname)}  variable, when {data($entptname)} variable is present</error>
