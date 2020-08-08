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
	
(: Rule SD1110 - Missing DS dataset :)
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
(: let $base := 'MSG_draft_define_2-1/' :)
(: let $define := 'define_2_1.xml' :)
(: let $defineversion := '2.1' :)
let $definedoc := doc(concat($base,$define))
(: get the location of the DS dataset :)
let $dsdatasetname := (
	if($defineversion and $defineversion='2.1') then
		$definedoc//odm:ItemGroupDef[@Name='DS']/def21:leaf/@xlink:href
    else $definedoc//odm:ItemGroupDef[@Name='DS']/def:leaf/@xlink:href
)
let $dsdatasetlocation := concat($base,$dsdatasetname)
(: we now have the location of the dataset, check whether it is available there :)
where (not(doc-available($dsdatasetlocation)))
return <warning rule="SD1110" dataset="DS" rulelastupdate="2020-08-08">Document {data($dsdatasetname)} could not be found in collection/folder {data($base)}</warning>		

