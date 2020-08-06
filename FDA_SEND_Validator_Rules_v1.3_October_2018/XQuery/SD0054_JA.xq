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

(: Rule SD0054: Variable in define.xml is not present in the dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the dataset definitions in the define.xml :)
for $datasetdef in $definedoc//odm:ItemGroupDef
    (: get the name and the dataset location and the dataset document :)
    let $datasetname := $datasetdef/@Name
	let $datasetlocation := (
		if($defineversion='2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := (
		if($datasetlocation) then doc(concat($base,$datasetlocation))
		else ()
	)
    (: get all the OIDs of the variables in the dataset definition :)
    let $varoids := $datasetdef/odm:ItemRef/@ItemOID
    (: now get all unique data point OIDs in the corresponding dataset :)
    let $datasetoids := distinct-values($datasetdoc//odm:ItemGroupData/odm:ItemData/@ItemOID)
    (: iterate over all variables in the define.xml for the given dataset  :)
    for $var in $varoids
        (: this is the variable OID, get the Name :)
        let $varname := $definedoc//odm:ItemDef[@OID=$var]/@Name
        (: compare with the unique OIDs in the dataset itself :)
        where not(functx:is-value-in-sequence($var,$datasetoids))
        (: if not found in the dataset, provide a warning :)
        return <warning rule="SD0054" dataset="{$datasetname}" variable="{$varname}" rulelastupdate="2019-08-17">Variable {data($varname)} in dataset {data($datasetname)} is defined in the define.xml but cannot be found in the dataset {data($datasetname)}</warning>	

