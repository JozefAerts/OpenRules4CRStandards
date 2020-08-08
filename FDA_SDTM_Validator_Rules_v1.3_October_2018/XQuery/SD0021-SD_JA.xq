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

(: Rule SD0021: One End Time-Point variable is expected to be populated when an event or an intervention occurred. 
 e.g./i.e., End Date/Time of Event or Intervention (--ENDTC), or End Relative to Reference Period (--ENRF), or End Relative to Reference Period (--ENRTPT) should not be missing,
 OR Occurrence (--OCCUR) = 'N' or Completion Status (--STAT) != '') or Duration (--DUR) != ''). :)
(: Applicable to INTERVENTIONS, EVENTS :)
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
declare variable $datasetname external;
(: find all dataset definitions  :)
(:  let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' :)
(: let $datasetname := 'AE' :)
(: get the define.xml dataset definition :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the provided dataset definitions in EVENTS and INTERVENTIONS :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' ]
    (: get the name of the dataset :)
    let $name := $datasetdef/@Name
    let $domain := $datasetdef/@Domain
    (: get the dataset location :)
	let $datasetlocation := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the dataset document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of --ENDTC, --ENRF, --ENRTPT, and their name:)
    let $endtcoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENDTC')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    ) 
    let $endtcname := concat($domain,'ENDTC') (: we use 'concat' for the case ENDTC is not defined at all :)
    let $enrfoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRF')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    ) 
    let $enrfname := concat($domain,'ENRF')  (: we use 'concat' for the case ENRF is not defined at all :)
    let $enrtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    ) 
    let $enrtptname := concat($domain,'ENRTPT')  (: we use 'concat' for the case ENRTPT is not defined at all :)
    (: return <test>{data($endtcoid)}  - {data($enrfoid)} - {data($enrtptoid)}</test> :)
    (: and the OIDs of --STAT and --OCCUR and --DUR :)  
    let $statoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STAT')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    let $occuroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'OCCUR')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    )
	let $duroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DUR')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    (: return <test>{data($statoid)}  - {data($occuroid)}</test> :)
    (: now iterate over all the records in the dataset 
    for which --OCCUR is NOT 'N' or --STAT is null or empty or --DUR is null or empty :)
	for $record in $datasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$statoid]) or not(odm:ItemData[@ItemOID=$duroid]) or odm:ItemData[@ItemOID=$occuroid]/@Value='N' ]
	let $recnum := $record/@data:ItemGroupDataSeq
	(: one of --ENDTC, --ENRF or --ENRTPT must be populated - if none of them is, give warning :)
	where not($record/odm:ItemData[@ItemOID=$endtcoid]/@Value) and not($record/odm:ItemData[@ItemOID=$enrfoid]/@Value) and not($record/odm:ItemData[@ItemOID=$enrtptoid]/@Value) 
	return <warning rule="SD0021" dataset="{data($name)}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">One of the End Time-Point variables {data($endtcname)}, {data($enrfname)} or {data($enrtptname)} must be populated</warning>

