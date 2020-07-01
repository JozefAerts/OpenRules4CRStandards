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

(: Rule SD1135: Study Day variables (*DY) value should not be negative in Exposure (EX) datasets :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: find all dataset definitions  :)
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all dataset definitions (for the case there is more than one) :)
for $datasetdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'EX') or @Domain='EX']
    (: get the name location of the dataset :)
    let $name := $datasetdef/@Name
    let $datasetlocation := $datasetdef/def:leaf/@xlink:href
    (: and the document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all *DY (includes --DY, --STDY, --ENDY) variables :)
    let $dyvaroids := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'DY')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    for $dyvaroid in $dyvaroids
        (: get the name of the variable :)
        let $varname := $definedoc//odm:ItemDef[@OID=$dyvaroid]/@Name
        (: iterate over all the records in the dataset for this variable, 
        and get the value :)
        for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dyvaroid]]
            let $recnum := $record/@data:ItemGroupDataSeq
            let $dyvalue := $record/odm:ItemData[@ItemOID=$dyvaroid]/@Value
            (: the value may not be negative :)
            where $dyvalue castable as xs:integer and xs:integer($dyvalue) < 0
            return <warning rule="SD1135" dataset="{$name}" variable="{$varname}" rulelastupdate="2019-08-16" recordnumber="{data($recnum)}">Value of {data($varname)} is not allowed to be negative in dataset {data($name)}. A value of {data($dyvalue)} was found</warning>	

