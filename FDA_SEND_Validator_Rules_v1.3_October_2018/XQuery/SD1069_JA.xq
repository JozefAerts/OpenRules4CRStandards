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

(: Rule SD1069 - Inconsistent value for --PARM within --PARMCD:
All values of a Parameter (--PARM) variables should be the same for a given value of a Parameter Short Name (--PARMCD) variables - TS domain
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Remark that rules FDAC087 and FDAC088 could easily be combined into a single rule :)
(: iterate over all TS datasets in the define.xml - 
 usually there will be only one :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='TS']
    (: get the dataset name and location :)
let $datasetname := (
	if($defineversion='2.1') then $itemgroup/def21:leaf/@xlink:href
	else $itemgroup/def:leaf/@xlink:href
)
    let $datasetdoc := (
		if($datasetname) then doc(concat($base,$datasetname))
		else ()
	)
    (: we need the OID of the TSPARMCD and TSPARM variables :)
    let $tsparmcdoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSPARMCD']/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID 
        return $a 
    )
    let $tsparmoid := (
        for $a in $definedoc//odm:ItemDef[@Name='TSPARM']/@OID 
        where $a = $itemgroup/odm:ItemRef/@ItemOID 
        return $a 
    )
    (: iterate over all the records in the TS dataset 
    where both TSPARMCD AND TSPARM are present - 
    this should essentially be the case for all records :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid] and odm:ItemData[@ItemOID=$tsparmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $tsparmcdvalue1 := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
        let $tsparmvalue1 := $record/odm:ItemData[@ItemOID=$tsparmoid]/@Value
        (: iterate over all following records having the same value for TSPARMCD:)
        for $record2 in $datasetdoc//odm:ItemGroupData[@data:ItemGroupDataSeq>$recnum][odm:ItemData[@ItemOID=$tsparmcdoid and @Value=$tsparmcdvalue1]]
            let $recnum2 := $record2/@data:ItemGroupDataSeq
            (: let $tsparmcdvalue2 := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value :)
            let $tsparmvalue2 := $record2/odm:ItemData[@ItemOID=$tsparmoid]/@Value 
            (: and compare the values - both must be equal :)
            where not($tsparmvalue1=$tsparmvalue2)
            return <warning rule="SD1069" dataset="TS" variable="TSPARM" rulelastupdate="2019-08-30" recordnumber="{data($recnum2)}">Inconsistent value for --PARM within --PARMCD: both records {data($recnum)} and {data($recnum2)} have --PARMCD='{data($tsparmcdvalue1)}' but the values for --PARM '{data($tsparmvalue1)}' and '{data($tsparmvalue2)}' are different</warning>
