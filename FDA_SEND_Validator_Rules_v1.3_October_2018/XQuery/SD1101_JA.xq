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

(: TODO: not well tested yet :)        
(: Rule SD1101 - Missing --ENTPT variable, when --ENRTPT variable is present:
End Reference Time Point (--ENTPT) variable must be included into the domain, when End Relative to Reference Time Point (--ENRTPT) variable is present
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
 
(: iterate over all datasets within INTERVENTIONS, EVENTS, FINDINGS, SE :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' or @Domain='SE']
    let $name := $dataset/@Name
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: Get the OID of the ENRTPT and ENTPT variable (when present) :)
    let $enrtptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENRTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $enrtptname := doc(concat($base,$define))//odm:ItemDef[@OID=$enrtptoid]/@Name
    let $entptoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'ENTPT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $entptname := concat($name,'ENTPT')  (: it might be that is not in the dataset :)
    (: when ENRTPT is present, also ENTPT must be present :)
    where $enrtptoid and not($entptoid)
    return <error rule="SD1101" variable="{data($enrtptname)}" dataset="{data($name)}"  rulelastupdate="2019-08-21">Missing {data($entptname)} variable, when {data($enrtptname)} variable is present</error>	
