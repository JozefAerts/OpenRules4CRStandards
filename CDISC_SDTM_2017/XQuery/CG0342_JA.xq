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
	
(: Rule CG0342 - --TRT != 'OTHER' :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define)) 
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS']
    let $name := $itemgroupdef/@Name
    (: we need the OID of --TRT (if any) and the complete name :)
    let $trtoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TRT') and string-length(@Name)=5]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and its full name :)
    let $trtname := $definedoc//odm:ItemDef[@OID=$trtoid]/@Name
    (: get the location of the dataset and the document itself :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: Iterate over all records in the dataset for which there is a --TRT variable :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData/@ItemOID=$trtoid]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $trt := $record/odm:ItemData[@ItemOID=$trtoid]/@Value
        (: The value of --TRT is not allowed to be 'OTHER' (case insensitive?)  :)
        where upper-case($trt) = 'OTHER'
        return <error rule="CG0342" dataset="{data($name)}" variable="{data($trtname)}" recordnumber="{data($recnum)}" rulelastupdate="2019-08-12">Value of {data($trtname)}='{data($trt)}' is not allowed to be equal to 'OTHER'</error>						
		
		