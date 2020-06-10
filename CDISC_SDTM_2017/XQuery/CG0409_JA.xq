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

xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the OID of the DM.STUDYID variable in the define.xml :)
let $dmitemgroupdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
let $dmstudyoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='STUDYID']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    ) 
(: get the DM dataset :)
let $dmdatasetname := $dmitemgroupdef/def:leaf/@xlink:href
let $dmdatasetpath := concat($base,$dmdatasetname)
let $dmstudyidunique := distinct-values(doc($dmdatasetpath)//odm:ItemData[@ItemOID=$dmstudyoid]/@Value)
(: Surprisingly there is no rule that STUDYID must be unique within DM :)
let $dmstudyid := $dmstudyidunique[1]  (: just for the worst case that STUDYID is NOT unique in DM :)
(: now iterate over all dataset definitions in the define.xml :)
for $itemgroupdef in doc(concat($base,$define))//odm:ItemGroupDef
    (: Also cover the case that there are several ItemDef[@Name='STUDYID'] e.g. one per dataset or domain :)
    let $dataset := $itemgroupdef/def:leaf/@xlink:href
    (: let $datasetpath := concat($base,$dataset) :)
    let $datasetpath := concat($base,$dataset)
    let $datasetname := $itemgroupdef/@Name
    (: find the variable for which the name is 'STUDYID' - there should be 0 or 1 :)
    let $studyoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='STUDYID']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    for $d in doc($datasetpath)//odm:ItemGroupData/odm:ItemData[@ItemOID=$studyoid]
        let $recordnumber := $d/../@data:ItemGroupDataSeq
        where not($d/@Value = $dmstudyid)
        return <error rule="CG0409" dataset="{data($datasetname)}" variable="STUDYID" rulelastupdate="2017-03-19" recordnumber="{data($recordnumber)}">STUDYID {data($d/@Value)} in dataset {data($dataset)} does not match the STUDYID {data($dmstudyid)} in the DM dataset</error>	
		
		