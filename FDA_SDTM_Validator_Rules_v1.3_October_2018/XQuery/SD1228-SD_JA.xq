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

(: Rule SD1228: Variable value not found in user-defined codelist when value-level condition occurs :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
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
(: find all dataset definitions  :)
(: let $base := '/db/fda_submissions/cdisc01/'  
let $define := 'define2-0-0-example-sdtm.xml'
let $datasetname := 'EG' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[@Name=$datasetname]
    let $name := $itemgroupdef/@Name
    (: get the location of the dataset and document :)
    let $datasetlocation := (
		if($defineversion = '2.1') then $itemgroupdef/def21:leaf/@xlink:href
		else $itemgroupdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the coded ValueList variables for this dataset
    We currently still need to exclude "External" CodeLists as long as they do not have a RESTful WS available,
    and as long as ODM/Dataset-XML does not support RESTful web services :)
    (: get the variables (OIDs) that do have an attached ValueList for this dataset :)
    let $valuelistvars := (
		if($defineversion = '2.1') then 
			for $a in $definedoc//odm:ItemDef[def21:ValueListRef/@ValueListOID]/@OID 
			where $a = $itemgroupdef/odm:ItemRef/@ItemOID 
			return $a 
		else 
			for $a in $definedoc//odm:ItemDef[def:ValueListRef/@ValueListOID]/@OID 
			where $a = $itemgroupdef/odm:ItemRef/@ItemOID 
			return $a 
    )
    (: return <test>{data($valuelistvars)}</test> :)
    (: iterate over the variables (OIDs) that do have an attached ValueList :)
    for $valuelistvar in $valuelistvars
        (: get the Name of the variable :)
        let $valuelistvarname := $definedoc//odm:ItemDef[@OID=$valuelistvar]/@Name
        (: get the reference valuelist itself :)
        let $valuelistoid := (
			if($defineversion = '2.1') then $definedoc//odm:ItemDef[@OID=$valuelistvar]/def21:ValueListRef/@ValueListOID
			else $definedoc//odm:ItemDef[@OID=$valuelistvar]/def:ValueListRef/@ValueListOID
		)
        let $valuelist := (
			if($defineversion = '2.1') then $definedoc//def21:ValueListDef[@OID=$valuelistoid]
			else $definedoc//def:ValueListDef[@OID=$valuelistoid]
		)
        (: iterate over the ValueList ItemRefs :)
        for $valuelistitemref in $valuelist/odm:ItemRef
            (: get the OID :)
            let $valuelistitemoid := $valuelistitemref/@ItemOID
            (: get the WhereClause :)
            let $whereclauserefoid := (
				if($defineversion = '2.1') then $valuelistitemref/def21:WhereClauseRef/@WhereClauseOID
				else $valuelistitemref/def:WhereClauseRef/@WhereClauseOID
			)
            (: and the corresponding WhereClauseDef :)
            let $whereclausedef := (
				if($defineversion = '2.1') then $definedoc//def21:WhereClauseDef[@OID=$whereclauserefoid]
				else $definedoc//def:WhereClauseDef[@OID=$whereclauserefoid]
			)
            (: get the item it is about - we currently only support 1 item and only the "EQ" comparator,
            and only the case that it is about data in the same dataset (e.g. STRESU depends of TESTCD value)
            This covers 90% of the cases :)
            let $whereclauseaboutitemoid := (
				if($defineversion = '2.1') then whereclausedef/odm:RangeCheck/@def21:ItemOID
				else whereclausedef/odm:RangeCheck/@def:ItemOID
			)
            let $checkvalue := $whereclausedef/odm:RangeCheck/odm:CheckValue/text()
            (: return <test>{data($whereclauseaboutitemoid)} - {data($checkvalue)}</test> :)
            (: pick up the corresponding ItemDef - but only when it does have a connected codelist :)
            for $valuelistitemdefcoded in $definedoc//odm:ItemDef[@OID=$valuelistitemoid and odm:CodeListRef/@CodeListOID]
                (: get the codelist itself and its coded values :)
                let $valuelistcodelistoid := $valuelistitemdefcoded/odm:CodeListRef/@CodeListOID
                (: exclude ExternalCodeList :)
                let $valuelistcodelist := $definedoc//odm:CodeList[@OID=$valuelistcodelistoid and not(odm:ExternalCodeList)]
                let $valuelistcodelistname := $valuelistcodelist/@Name
                (: get the coded values :)
                let $valuelistcodedvalues := $valuelistcodelist/odm:*/@CodedValue
                (: get all the records in the dataset that are about the given valuelist variable :)
                (: return <test>{data($valuelistvar)} - {data($whereclauseaboutitemoid)} - {data($checkvalue)} - {data($valuelistcodedvalues)}</test> :)
                (: iterate over all the records where the WhereClause applies to, 
                i.e. $whereclauseaboutitemoid = $checkvalue :)
                for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$whereclauseaboutitemoid and @Value=$checkvalue]]
                    let $recnum := $record/@data:ItemGroupDataSeq
                    (: get the value of the dependent variable :)                  
                    let $dependentvarvalue := $record/odm:ItemData[@ItemOID=$valuelistvar]/@Value
                    (: the dependent variable value must be a value in the codelist :)
                    where not(functx:is-value-in-sequence($dependentvarvalue,$valuelistcodedvalues))
                    return <error rule="SD1228" dataset="{$datasetname}" variable="{$valuelistvarname}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">Variable {data($valuelistvarname)} valuelist value '{data($dependentvarvalue)}' is not found in user-defined codelist '{data($valuelistcodelistname)}'. One of [{data($valuelistcodedvalues)}] is expected</error>

