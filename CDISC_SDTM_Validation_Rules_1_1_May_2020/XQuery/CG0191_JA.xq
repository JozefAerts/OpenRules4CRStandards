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

(: Rule CG0191: When MS dataset present in study then MB dataset present in study  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external; 
declare variable $define external;  
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the MS dataset definition :)
let $msitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='MS']
(: and the location of the dataset and the document itself :)
let $msdatasetlocation := $msitemgroupdef/def:leaf/@xlink:href
let $msdatasetdoc := doc(concat($base,$msdatasetlocation))
(: get the MB dataset (if any) :)
let $mbitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='MB']
(: and the location of the dataset and the document itself :)
let $mbdatasetlocation := $mbitemgroupdef/def:leaf/@xlink:href
let $mbdatasetdoc := doc(concat($base,$mbdatasetlocation))
(: when the MS dataset exists, also the MB document must exist :)
where $msdatasetlocation and doc-available($msdatasetdoc) and (not($mbdatasetlocation) or not($mbdatasetdoc)) 
return <error rule="CG0191" dataset="MS" rulelastupdate="2020-06-15">MB dataset exists, but MS dataset is missing</error>				
		
	