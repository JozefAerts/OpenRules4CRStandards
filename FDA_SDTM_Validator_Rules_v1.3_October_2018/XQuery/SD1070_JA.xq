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

(: Rule SD1070 - Inconsistent value for --PARMCD within --PARM:
All values of a Parameter Short Name (--PARMCD) variables should be the same for a given value of a Parameter (--PARM) variables - TS domain
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
(: Remark that rules SD1069 and SD1070 could easily be combined into a single rule :)

(: iterate over all TS datasets in the define.xml - 
 usually there will be only one :)
for $itemgroup in $definedoc//odm:ItemGroupDef[@Name='TS']
    (: get the dataset name and location :)
	let $datasetname := (
		if($defineversion = '2.1') then $itemgroup/def21:leaf/@xlink:href
		else $itemgroup/def:leaf/@xlink:href
	)
    let $dataset := concat($base,$datasetname)
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
    for $record in doc($dataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid] and odm:ItemData[@ItemOID=$tsparmoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $tsparmcdvalue1 := $record/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value
        let $tsparmvalue1 := $record/odm:ItemData[@ItemOID=$tsparmoid]/@Value
        (: iterate over all following records having the same value for TSPARM:)
        for $record2 in doc($dataset)//odm:ItemGroupData[@data:ItemGroupDataSeq>$recnum][odm:ItemData[@ItemOID=$tsparmoid and @Value=$tsparmvalue1]]
            let $recnum2 := $record2/@data:ItemGroupDataSeq
            let $tsparmcdvalue2 := $record2/odm:ItemData[@ItemOID=$tsparmcdoid]/@Value 
            (: and compare the values - both must be equal :)
            where not($tsparmcdvalue1=$tsparmcdvalue2)
            return <warning rule="SD1070" dataset="TS" variable="TSPARMCD" rulelastupdate="2020-08-08" recordnumber="{data($recnum2)}">Inconsistent value for --PARMCD within --PARM: both records {data($recnum)} and {data($recnum2)} have --PARM='{data($tsparmvalue1)}' but the values for --PARMCD '{data($tsparmcdvalue1)}' and '{data($tsparmcdvalue2)}' are different</warning>	
