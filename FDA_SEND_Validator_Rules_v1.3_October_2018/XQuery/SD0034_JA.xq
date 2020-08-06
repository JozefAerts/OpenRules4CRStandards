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
	
(: Rule SD0034 - Missing value for --TPTREF, when --ELTM is provided
Time Point Reference (--TPTREF) should not be NULL, when Planned Elapsed Time from Time Point Ref (--ELTM) is populated :)
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
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'
		or @Domain='CO']
    let $name := $dataset/@Name
	let $datasetname := (
		if($defineversion='2.1') then $dataset/def21:leaf/@xlink:href
		else $dataset/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: Get the OID of the TPTREF and ELTM variable (when present) :)
    let $tptrefoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TPTREF')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    (: let $tptrefname := $definedoc//odm:ItemDef[@OID=$tptrefoid]/@Name :)
    let $tptrefname := concat($name,'TPTREF')
    let $eltmoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ELTM')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $eltmname := $definedoc//odm:ItemDef[@OID=$eltmoid]/@Name
    (: iterate over all the records that do have an ELTM data point :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$eltmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of the TPTREF and ELTM data points (if any) :)
        let $tptrefvalue := $record/odm:ItemData[@ItemOID=$tptrefoid]/@Value
        let $eltmvalue := $record/odm:ItemData[@ItemOID=$eltmoid]/@Value 
        (: when ELTM is populated, TPTREF must be present :)
        where $eltmvalue and not($tptrefvalue)
        return <warning rule="SD0034" variable="{data($tptrefname)}" dataset="{data($name)}" rulelastupdate="2019-08-19" recordnumber="{data($recnum)}">Missing value for {data($tptrefname)} when {data($eltmname)} is populated, value={data($eltmvalue)}</warning>	
