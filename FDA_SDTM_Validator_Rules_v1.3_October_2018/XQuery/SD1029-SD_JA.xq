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

(: Rule SD1029: Non-ASCII or non-printable characters in variable.
 We only check on non-ascii, as every character is printable - depends on the printer ... :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'LB' :)
(: the define.xml document :)
let $definedoc := doc(concat($base,$define))
(: get the dataset definition :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $datasetdef/@Name
    (: get the dataset location :)
    let $datasetlocation := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    (: and the document itself :)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over all the data points :)
        for $datapoint in $record/odm:ItemData
            (: get the OID and Name of the datapoint :)
            let $varoid := $datapoint/@ItemOID
            let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
            (: get the value :)
            let $varvalue := $datapoint/@Value
            (: if the string-length > 0, the all the characters must be ASCII - 
            see e.g. https://stackoverflow.com/questions/51521676/use-xpath-to-check-if-a-string-has-only-ascii-characters :)
            where string-length($varvalue) > 0 and not(matches($varvalue,'^[ -~\n\t]+$'))  
            return <error rule="SD1029" dataset="{$datasetname}" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}" variable="{$varname}">Variable value '{data($varvalue)}' contains non-ASCII characters</error>	

