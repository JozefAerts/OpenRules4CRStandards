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
	
(: Rule SD SD1021: Character values should not have leading spaces or only have a period character :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $datasetname external;
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' 
let $datasetname := 'LB' :)
(: get the dataset location :)
let $datasetdef := doc(concat($base,$define))//odm:ItemGroupDef[@Name=$datasetname]
let $datasetlocation := $datasetdef/def:leaf/@xlink:href
(: get the OIDs of the variables that are of type 'char', 
 : which are all the ones that are not "integer" or "float" :)
let $charvaroids := (
    for $a in doc(concat($base,$define))//odm:ItemDef[not(@DataType='float' or @DataType='integer')]/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
)
(:  testing only: return <test>{data($charvaroids)}</test>  :)
(: iterate over all data points that are not of type 'integer' or 'float' :)
for $record in doc(concat($base,$datasetlocation))//odm:ItemGroupData
    (: get the record number :)
    let $recnum := $record/@data:ItemGroupDataSeq
    for $datapoint in $record/odm:ItemData[functx:is-value-in-sequence(@ItemOID,$charvaroids)] 
        (: get the name from the OID :)
        let $varname := doc(concat($base,$define))//odm:ItemDef[@OID=$datapoint/@ItemOID]/@Name
        (: get the value :)
        let $value := $datapoint/@Value
        (: when the first character is a space, or the whole value is '.' give an warning :)
        where $value = '.' or starts-with($value,' ')
        return <warning rule="SD1021" dataset="{data($datasetname)}" variable="{data($varname)}" recordnumber="{data($recnum)}" rulelastupdate="2019-08-15">Unexpected character value in non-numeric variable value {data($varname)}. Value '{data($value)}' was found</warning>	 

