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
	
(: Rule CG0346 - --TERM != 'MULTIPLE' :)
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
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='EVENTS']
    let $name := $itemgroupdef/@Name
    (: we need the OID of --TERM (if any) and the complete name :)
    let $termoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'TERM') and string-length(@Name)=6]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: and its full name :)
    let $termname := $definedoc//odm:ItemDef[@OID=$termoid]/@Name
    (: get the location of the dataset and the document itself :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: Iterate over all records in the dataset for which there is a --TERM variable :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData/@ItemOID=$termoid]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $term := $record/odm:ItemData[@ItemOID=$termoid]/@Value
        (: The value of --TERM is not allowed to be 'MULTIPLE' (case insensitive?)  :)
        where upper-case($term) = 'MULTIPLE'
        return <error rule="CG0346" dataset="{data($name)}" variable="{data($termname)}" recordnumber="{data($recnum)}" rulelastupdate="2019-08-12">Value of {data($termname)}='{data($term)}' is not allowed to be equal to 'MULTIPLE'</error>						
		
		