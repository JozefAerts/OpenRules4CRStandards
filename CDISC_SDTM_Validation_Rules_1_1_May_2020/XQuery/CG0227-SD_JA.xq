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

(: Rule CG0227 - When DM.RFENDTC = null then --ENRF = null :)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the location of the DM dataset :)
let $dmdataset := (
	if($defineversion='2.1') then $definedoc//odm:ItemGroupDef[@Name='DM']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='DM']/def:leaf/@xlink:href
)
let $dmdatasetlocation := concat($base,$dmdataset)
let $dmdatasetdoc := doc($dmdatasetlocation)
(: get the OID of the RFENDTC variable :)
let $rfendtcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RFENDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a   
)
(: get the OID of the USUBJID variable :)
let $dmusubjidoid := (
    for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a  
)
(: iterate over all other datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[not(@Name='DM')][@Name=$datasetname]
    let $name := $datasetdef/@Name
    (: get the dataset location :)
	let $datasetlocation := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of the --ENRF variable (if any) :)
    let $enrfoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'ENRF')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a  
    )
    let $enrfname := $definedoc//odm:ItemDef[@OID=$enrfoid]/@Name
    (: and the OID of USUBJID in this dataset :)
    let $usubjidoid := (
        for $a in $definedoc//odm:ItemDef[@Name='USUBJID']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a  
    )
    (: iterate over all the records in the dataset for which STRF is defined :)
    for $record in $datasetdoc[$enrfoid and $usubjidoid]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the USUBJID in order to be able to do the look up in DM :)
        let $usubjid := $record/odm:ItemData[@ItemOID=$usubjidoid]/@Value
        (: get the value of value of --ENRF :)
        let $enrf := $record/odm:ItemData[@ItemOID=$enrfoid]/@Value
        (: and pick up the record in DM :)
        let $dmrecord := $dmdatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dmusubjidoid and @Value=$usubjid]]
        (: get the value of DM.RFENDTC (if any) :)
        let $rfendtc := $dmrecord/odm:ItemData[@ItemOID=$rfendtcoid]/@Value
        (: When DM.RFENDTC = null then --ENRF = null :)
        where not($rfendtc) and $enrf
        return <error rule="CG0227" dataset="{data($name)}" variable="{data($name)}" rulelastupdate="2020-08-04" recordnumber="{data($recnum)}">{data($enrfname)}={data($enrf)} is found although RFENDTC in DM is null</error>			
		
	