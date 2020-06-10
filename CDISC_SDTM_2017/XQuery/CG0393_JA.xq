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

(: Rule CG0393 - AESLIFE in ('Y','N') :)
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
(: get the AE dataset(s) :)
for $aeitemgroupdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'AE')]
    let $name := $aeitemgroupdef/@Name
    (: we need the OID of AESLIFE :)
    let $aeslifeoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESLIFE']/@OID 
        where $a = $aeitemgroupdef/odm:ItemRef/@ItemOID
        return $a
    ) 
    (: get the dataset location and document :)
    let $datasetlocation := $aeitemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset for which AESLIFE is populated :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$aeslifeoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and the value of AESLIFE :)
        let $aeslife := $record/odm:ItemData[@ItemOID=$aeslifeoid]/@Value
        (: AESLIFE must be one of 'Y' or 'N' :)
        where not($aeslife='Y' or $aeslife='N')
        return <error rule="CG0393" dataset="{data($name)}" variable="AESLIFE" recordnumber="{data($recnum)}" rulelastupdate="2017-03-17">Value of AESLIFE='{data($aeslife)}' must be one of 'Y' or 'N'</error>						
		
		