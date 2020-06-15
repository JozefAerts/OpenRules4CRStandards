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

(: Rule CG0297 - TV.ARMCD value length <= 20 :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over the TV dataset definitions, there should be only 1 :)
for $tvitemgroupdef in $definedoc//odm:ItemGroupDef[@Name='TV']
    (: we need the OID of ARMCD in TV :)
    let $tvarmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='ARMCD']/@OID
        where $a = $tvitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location :)
    let $tvdatasetlocation := $tvitemgroupdef/def:leaf/@xlink:href
    let $tvdatasetdoc := doc(concat($base,$tvdatasetlocation))
    (: iterate over all the records in the TV dataset :)
    (: iterate over all records in the TV dataset :)
    for $record in $tvdatasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ARMCD in TV :)
        let $tvarmcd := $record/odm:ItemData[@ItemOID=$tvarmcdoid]/@Value
        (: the length of the ARMCD value should not be more than 20 characters :)
        where string-length($tvarmcd) > 20
        return <error rule="CG0297" dataset="TV" variable="ARM" recordnumber="{data($recnum)}" rulelastupdate="2020-06-15">TV.ARMCD='{data($tvarmcd)}' has more than 20 characters</error>											
		
	