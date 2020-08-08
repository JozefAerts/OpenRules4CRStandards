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
	
(: Rule SD1118 - Neither --STDTC, --DTC nor  --STDY are populated in DS:
At least one value of two variables Start Date/Time (--STDTC) and Start Study Day (--STDY) should be populated
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
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the location of the DS dataset :)
let $dsdataset := $definedoc//odm:ItemGroupDef[@Name='DS']
let $dsdatasetname := (
	if($defineversion = '2.1') then $dsdataset/def21:leaf/@xlink:href
	else $dsdataset/def:leaf/@xlink:href
)
let $dsdatasetlocation := concat($base,$dsdatasetname)
(: Get the OID of the DSSTDTC, DSDTC and DSSTDY and DS variables :)
let $dssdttcoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
        return $a  
)
let $dsstdyoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSSTDY']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
        return $a    
)
let $dsdtcoid := (
	for $a in $definedoc//odm:ItemDef[@Name='DSDTC']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
        return $a 
)
(: iterate over all the records in the dataset :)
for $record in doc($dsdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and the values of the DSSDTDTC and DSSTDY and DSDTC data points (when present) :)
    let $dsstdtcvalue := $record/odm:ItemData[@ItemOID=$dssdttcoid]/@Value
    let $dsstdyvalue := $record/odm:ItemData[@ItemOID=$dsstdyoid]/@Value
	let $dsdtcvalue := $record/odm:ItemData[@ItemOID=$dsdtcoid]/@Value
    (: at least one of the three must be present :)
    where not($dsstdtcvalue) and not($dsstdyvalue) and not($dsdtcvalue)
    return <warning rule="SD1118" dataset="DS" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Neither DSSDTDTC nor DSSTDY nor DSDTC are populated in dataset {data($dsdatasetname)}</warning>	
