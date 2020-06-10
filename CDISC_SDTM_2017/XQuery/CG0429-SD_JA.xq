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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all INTERVENTIONS, EVENTS and FINDINGS domains :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname][upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS']
    let $name := $dataset/@Name
    let $domain := $dataset/@Domain
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: get the OID of --CAT and --SCAT and VAMT variables :)
    let $catoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'CAT') and string-length(@Name)=5]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $catname := //odm:ItemDef[@OID=$catoid]/@Name
    let $scatoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'SCAT') and string-length(@Name)=6]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $scatname := //odm:ItemDef[@OID=$scatoid]/@Name
    (: iterate over all records for which --SCAT is populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$scatoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the value of the --SCAT variable :)
        let $scatvalue := $record/odm:ItemData[@ItemOID=$scatoid]/@Value
        (: and check whether CAT is populated :)
        let $catvalue := $record/odm:ItemData[@ItemOID=$catoid]/@Value
        where not($catvalue)
        return <error rule="CG0429" dataset="{data($name)}" variable="{data($catname)}" rulelastupdate="2019-08-13" recordnumber="{data($recnum)}">{data($catname)}=null although {data($scatname)}='{data($catvalue)}' is not null</error>				
		
		