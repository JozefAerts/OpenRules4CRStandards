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
	
(: Rule CG0370 - When IDVAR != null then IDVAR is variable in domain = RDOMAIN :)
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
let $definedoc := doc(concat($base,$define))
(: iterate over all SUPP--, CO and RELREC dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name='CO' or @Name='RELREC' or starts-with(@Name,'SUPP')]
    let $name := $itemgroupdef/@Name
    (: get the OID of RDOMAIN and of IDVAR:)
    let $rdomainoid := (
        for $a in $definedoc//odm:ItemDef[@Name='RDOMAIN']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $idvaroid := (
        for $a in $definedoc//odm:ItemDef[@Name='IDVAR']/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location and the document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset for which there is a value of RDOMAIN and of IDVAR :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$rdomainoid] and odm:ItemData[@ItemOID=$idvaroid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of RDOMAIN and of IDVAR :)
        let $rdomain := $record/odm:ItemData[@ItemOID=$rdomainoid]/@Value
        let $idvarvalue := $record/odm:ItemData[@ItemOID=$idvaroid]/@Value
        (: look up whether there is such a variable in the parent domain RDOMAIN :)
        where $idvarvalue and (not($definedoc//odm:ItemDef[@Name=$idvarvalue]) or not($definedoc//odm:ItemGroupDef[@Name=$rdomain or starts-with(@Name,$rdomain)]/odm:ItemRef[@ItemOID=$definedoc//odm:ItemDef[@Name=$idvarvalue]/@OID]))
        return <error rule="CG0370" dataset="{data($name)}" variable="RDOMAIN" recordnumber="{data($recnum)}" rulelastupdate="2017-03-15">Variable '{data($idvarvalue)}' was not found in the parent dataset of the referenced domain RDOMAIN='{data($rdomain)}' </error>
		
		