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

(: When MHCAT != null then MHCAT != the same value for all records :)
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
(: get the MH dataset - take splitted domains into account :)
let $mhitemgroupdef := $definedoc//odm:ItemGroupDef[starts-with(@Name,'MH') or @Domain='MH']
let $name := $mhitemgroupdef/@Name
let $mhdatasetlocation := (
	if($defineversion='2.1') then $mhitemgroupdef/def21:leaf/@xlink:href
	else $mhitemgroupdef/def:leaf/@xlink:href
)
let $mhdatasetdoc := doc(concat($base,$mhdatasetlocation))
(: get the OID of the MHCAT variable :)
let $mhcatoid := (
    for $a in $definedoc//odm:ItemDef[@Name='MHCAT']/@OID 
    where $a = $mhitemgroupdef/odm:ItemRef/@ItemOID
    return $a
)
(: get the distinctvalues of MHCAT (when MHCAT not null) :)
let $mhcatvalues := $mhdatasetdoc//odm:ItemGroupData/odm:ItemData[@ItemOID=$mhcatoid and @Value!='']/@Value
let $mhcatdistinctvalues := distinct-values($mhcatvalues)
(: the number of distinct values of MHCAT must be 2 or greater :)
let $count := count($mhcatdistinctvalues)
where $count < 2
return <error rule="CG0077" variable="MHCAT" dataset="MH" rulelastupdate="2020-08-04">Only {data($count)} distinct value '{data($mhcatdistinctvalues)}' values for MHCAT was found in the {data($name)} dataset</error>		
		
	