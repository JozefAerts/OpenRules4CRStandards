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
	
(: Rule SD1106 - Missing AE dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the location of the AE dataset :)
let $aedatasetname := ( 
	if($defineversion and $defineversion='2.1') then
		$definedoc//odm:ItemGroupDef[@Name='AE']/def21:leaf/@xlink:href
	else $definedoc//odm:ItemGroupDef[@Name='AE']/def:leaf/@xlink:href
)
let $aedatasetlocation := concat($base,$aedatasetname)
(: we now have the location of the dataset, check whether it is available there :)
where (not(doc-available($aedatasetlocation)))
return <warning rule="SD1106" dataset="AE" rulelastupdate="2020-08-08">Document {data($aedatasetname)} could not be found in collection {data($base)}</warning>		
