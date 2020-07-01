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

(: Rule SD1071 - Dataset is greater than 5 GB in size :)
(: Implementation ONLY in compbination with BaseX :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external;
(: In the example, we use the path to the file. 
This may look differently when the file is in a native XML database :)
(: let $base := 'C:\CDISC_Standards\CDISC_SEND\PDS2014_SEND_Data_Set\' :)
(: let $define := 'define2-0-0_DS.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over all the dataset definitions :)
for $dataset in $definedoc//odm:ItemGroupDef	
	let $name := $dataset/@Name
    (: Get the location of the file :)
    let $datasetloc := $dataset/def:leaf/@xlink:href
    (: BaseX-specific: get the file size :)
    let $filesize := file:size(concat($base,$datasetloc)) div (1024*1024)
    where $filesize > 5*1024
    return <warning rule="SD1071" dataset="{$name}" rulelastupdate="2020-07-01">Size of file {data($datasetloc)} is larger than 5GB - file size found = {$filesize} MB </warning>

