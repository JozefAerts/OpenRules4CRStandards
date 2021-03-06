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

(: Rule CG0465 - When IDVAR = null then IDVARVAL = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the SUPP-- and CO dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'SUPP') or @Name='CO']
    let $name := $itemgroupdef/@Name
    (: get the OIDs of IDVAR and IDVARVAL :)
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $idvarvaloid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVARVAL']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the location of the dataset and the document  :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records for which IDVAR=null :)
    for $record in $datasetdoc//odm:ItemGroupData[not(odm:ItemData[@ItemOID=$idvaroid])]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of IDVARVAL :)
        let $idvarval := $record/odm:ItemData[@ItemOID=$idvarvaloid]/@Value
        (: IDVARVAL must be null :)
        where $idvarval and string-length($idvarval)>0
        return <error rule="CG0465" dataset="{data($name)}" variable="IDVARVAL" rulelastupdate="2017-03-25">IDVARVAL='{data($idvarval)}' must be null as IDVAR=null</error>													
		
		