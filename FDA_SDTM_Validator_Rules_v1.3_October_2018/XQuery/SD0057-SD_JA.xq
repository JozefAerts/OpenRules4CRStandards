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
	
(: Rule SD0057: SDTM Expected variable not found :)
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
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
(: The base of the RESTful web service to get whether a variable is "required", "expected" or "permissible" :)
let $webservicebase := 'http://www.xml4pharmaserver.com:8080/CDISCCTService/rest/CDISCCoreFromSDTMVariable/'
(: get the define document :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM-IG version :)
(: TODO: for v.2.1 get standard version at the dataset definition level :)
let $igversion := (
	if($defineversion = '2.1') then $definedoc//odm:MetaDataVersion/def21:Standards/def21:Standard[@Type='IG'][1]/@Version
	else $definedoc//odm:MetaDataVersion/@def:StandardVersion
)
(: iterate over all the provided dataset definitions in the define.xml :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    (: get the name of the dataset, the domain and the dataset location :)
    let $name := $datasetdef/@Name
    let $datasetlocation := (
		if($defineversion = '2.1') then $datasetdef/def21:leaf/@xlink:href
		else $datasetdef/def:leaf/@xlink:href
	)
    let $domain := $datasetdef/@Domain
    (: create a list of all "expected" variables in the dataset
    This uses an XML4Pharma RESTful web service.
    TODO: use the CDISC Library API :)
    let $expectedvaroids := (
        for $varoid in $datasetdef/odm:ItemRef/@ItemOID
            let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name  (: the variable name :)
            (: get the "core" ("required", "expected" or "permissible" from the RESTful web service :)
            let $query := concat($webservicebase,$igversion,'/',$domain,'/',$varname)
            let $core := doc($query)//Response/text()
            where $core = 'Exp'
            return $varoid (: we return the OID, as this will be more direct for checking the presence :)
    )
    (: return <test>{data($expectedvaroids)}</test> :)
    (: check whether each of the expected variables is at least defined in the define.xml - 
    which does mean that there is a column for it, empty or not :)
    for $oid in $expectedvaroids
        let $varname := $definedoc//odm:ItemDef[@OID=$oid]/@Name  (: needed for reporting :)
        let $expectedpresent := $datasetdef/odm:ItemRef[@ItemOID=$oid]  (: a boolean :)
        where not($expectedpresent)  (: expected variable is not present :)
        return <warning rule="SD1015" dataset="{data($name)}" variable="{$varname}" rulelastupdate="2020-08-08">Expected variable {data($varname)} was not found in dataset {data($name)} for domain {data($domain)}</warning>		

