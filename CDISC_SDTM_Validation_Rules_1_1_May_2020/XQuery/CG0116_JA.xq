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

(: Rule CG0116 - When --LOC not present in dataset then --DIR not present in dataset
Applicable to INTERVENTIONS and FINDINGS :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the datasets , but only the INTERVENTIONS and FINDINGS ones :)
for $dataset in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='FINDINGS' or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='FINDINGS']
    (: get the dataset :)
    let $name := $dataset/@Name
    (: the prefix (first 2 characters) is either the domain name or the first characters of the dataset name (case splitted domains) :)
    let $prefix := (
        if($dataset/@Domain) then $dataset/@Domain
        else substring($name,1,2)
    )
    (: get the OID and name of --LOC and --PORTOT :)
    let $locoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'LOC')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $locname := concat($prefix,'LOC')
    (: get the OID and name of --DIR :)
    let $diroid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DIR')]/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dirname := concat($prefix,'DIR')
    (: When --LOC not present in dataset then --DIR not present in dataset :)
    where not($locoid) and $diroid  (: --LOC is not present, but --DIR is present :)
        return 
            <error rule="CG0116" dataset="{data($name)}" variable="{data($dirname)}" rulelastupdate="2020-08-04">{data($dirname)} is present although {data($locname)} is present in dataset {data($name)}</error>				
		
	