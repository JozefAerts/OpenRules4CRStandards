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

(: Rule SD1314: DSDECOD is not 'COMPLETED', when DSTERM='COMPLETED' - When Reported Term for the Disposition Event (DSTERM) is 'COMPLETED', Standardized Disposition Term (DSDECOD) should have the same value 'COMPLETED' :)
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
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml'  :)
let $definedoc := doc(concat($base,$define))
(: get the DS dataset :)
for $dsdatasetdef in $definedoc//odm:ItemGroupDef[@Name='DS' or @Domain='DS']
    let $name := $dsdatasetdef/@Name (: for the ultimate case of DS splitted datasets :)
    (: get the location and the dataset document itself :)
	let $datasetlocation := (
		if($defineversion = '2.1') then $dsdatasetdef/def21:leaf/@xlink:href
		else $dsdatasetdef/def:leaf/@xlink:href
	)
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: get the OID of DSDECOD and of DSTERM in DS  :)
    let $dsdecodoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSDECOD']/@OID 
        where $a = $dsdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $dstermoid := (
        for $a in $definedoc//odm:ItemDef[@Name='DSTERM']/@OID 
        where $a = $dsdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records in the dataset for which DSTERM = 'COMPLETED' :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$dstermoid and @Value='COMPLETED']]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the DSDECOD value :)
        let $dsdecod := $record/odm:ItemData[@ItemOID=$dsdecodoid]/@Value
        (: DSDECOD must also be "COMPLETED"  :)
        where not($dsdecod = 'COMPLETED')
        return <error rule="SD1314" variable="DSDECOD" dataset="{$name}" recordnumber="{$recnum}" rulelastupdate="2020-08-08">Value for DSDECOD='{data($dsdecod)}' must be 'COMPLETED', as DSTERM='COMPLETED'</error>				
	
	