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
	
(: Rule SD1128 - Invalid value for RELTYPE variable:
Relationship Type (RELTYPE)  variable values should be populated with terms 'ONE', 'MANY', when Related Records (RELREC) dataset is used to identify relationships between datasets.
TODO: how can we see that the RELREC dataset is used to identify relationships between datasets?
The only thing we do here is check whether RELTYPE is either empty (but then the data point should be absent when using Dataset-XML
or either has the value "ONE" or "MANY"
:)
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
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all RELREC datasets in the define.xml - 
 usually there will be only one :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='RELREC']
    (: get the dataset name and location :)
    let $datasetname := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
    (: get the OID of the "RELTYPE" variable :)
    let $reltypeoid := (
    for $a in $definedoc//odm:ItemDef[@Name='RELTYPE']/@OID 
    where $a = $itemgroup/odm:ItemRef/@ItemOID 
    return $a 
    )
    (: now iterate over all RELREC records for which there IS a RELTYPE datapoint :)
    for $record in doc($dataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$reltypeoid]]
        (: get the record number and the value for RELTYPE :)
        let $recnum := $record/@data:ItemGroupDataSeq
        let $value := $record/odm:ItemData[@ItemOID=$reltypeoid]/@Value
        (: the value may only be 'ONE' or 'MANY' - if null, the data point should not exist in Dataset-XML  :)
        where not($value='ONE') and not($value='MANY')
        return <error rule="SD1128" dataset="RELREC" variable="RELTYPE" recordnumber="{data($recnum)}" rulelastupdate="2020-08-08">Invalid value for RELTYPE variable: only 'ONE' or 'MANY' is allowed. The value '{data($value)}'was found</error>
