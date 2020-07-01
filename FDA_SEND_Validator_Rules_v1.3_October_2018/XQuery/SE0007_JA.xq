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
	
(: Rule SE0007 - Missing TX dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the location of the TX dataset :)
let $txdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TX']/def:leaf/@xlink:href
let $txdatasetlocation := concat($base,$txdatasetname)
(: we now have the location of the dataset, check whether it is available there :)
where (not(doc-available($txdatasetlocation)))
return <warning rule="SE0007" dataset="TX" rulelastupdate="2020-06-25">Document TX could not be found in collection {data($base)}</warning>
