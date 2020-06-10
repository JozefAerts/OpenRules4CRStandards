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

(: Rule CG0021: coded Value must be in the associated codelist (if any) or have the value 'OTHER' :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
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
(: find all dataset definitions  :)
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all dataset definitions :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    (: get the location of the dataset and document :)
    let $datasetlocation := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OIDs of the coded variables for this dataset.
    We currently still need to exclude "External" CodeLists as long as they do not have a RESTful WS available,
    and as long as ODM/Dataset-XML does not support RESTful web services :)
    let $codedoids := (
        for $a in $definedoc//odm:ItemDef[odm:CodeListRef]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID 
        return $a 
    )
    (: iterate over all records in the dataset, but only when they contain coded values :)
    for $record in $datasetdoc[count($codedoids)>0]//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over the coded variables :)
        for $codeditem in $record/odm:ItemData[functx:is-value-in-sequence(@ItemOID,$codedoids)]
            (: get the OID and value :)
            let $oid := $codeditem/@ItemOID
            let $value := $codeditem/@Value
            (: also get the variable name for reporting :)
            let $varname := $definedoc//odm:ItemDef[@OID=$oid]/@Name
            (: look up the allowed values for this coded item in the define.xml :)
            let $codelistoid := $definedoc//odm:ItemDef[@OID=$oid]/odm:CodeListRef/@CodeListOID
            (: P.S. exclude "ExternalCodeList"  :)
            let $allowedvalues := $definedoc//odm:CodeList[not(odm:ExternalCodeList)][@OID=$codelistoid]/odm:*/@CodedValue
            (: the value must be one of the coded values OR 'MULTIPLE' :)
            where count($allowedvalues) > 0 and not(functx:is-value-in-sequence($value,$allowedvalues)) and not($value='OTHER')
            return <error rule="CG0021" dataset="{data($name)}" variable="{data($varname)}" recordnumber="{data($recnum)}" rulelastupdate="2019-08-07">Value for variable {data($varname)}: value {data($value)} not found in associated codelist {data($codelistoid)} and is not 'OTHER'</error>									
		
		