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
	
(: Rule FDAC203 - Missing value for DSCAT:
Category for Disposition Event (DSCAT) should be populated
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
(: Get the DS dataset :)
let $dsdataset := $definedoc//odm:ItemGroupDef[@Name='DS']
let $dsdatasetname := (
	if($defineversion = '2.1') then $dsdataset/def21:leaf/@xlink:href
	else $dsdataset/def:leaf/@xlink:href
)
let $dsdatasetlocation := concat($base,$dsdatasetname)
(: and get the OID of the DSCAT variable :)
let $dscatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='DSCAT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name='DS']/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all records in the DS dataset :)
for $record in doc($dsdatasetlocation)//odm:ItemGroupData
    let $recnum := $record/@data:ItemGroupDataSeq
    (: and check whether DSCAT is populated :)
    let $dscatvalue := $record/odm:ItemData[@ItemOID=$dscatoid]/@Value
    where not($dscatvalue)
    return <warning rule="SD1035" dataset="DS" variable="DSCAT" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">Missing value for DSCAT</warning>	
