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
(: Implementation ONLY in compbination with eXist :)
(: see: http://rvdb.wordpress.com/2013/02/26/an-xquery-script-for-listing-the-contents-of-collections-in-exist-db/ :)
(: TODO - xmldb:get-child-resources is eXist-specific, does not work for files, and does not work with BaseX :)
(: suggestion: use collection('file:///a/b/c/d?select=*.xml') - see http://stackoverflow.com/questions/5601764/xquery-all-files-under-a-specific-directory :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: TODO: xmldb:get-child-resources only works for eXist-DB :)
for $child in xmldb:get-child-resources($base)
    let $datasetname := upper-case(substring-before($child,'.'))
    let $path := concat($base, $child)
    (: TODO: test further: file sizes obtained here are about 20% too high :)
    let $size := fn:ceiling(xmldb:size($base, $child) div (1024*1024))  (: file size in MB :)
    where $size > (5*1024)
    return
    <warning rule="SD1071" dataset="{$datasetname}" rulelastupdate="2016-03-25">Size of file {$child} is larger than 1GB - file size found = {$size} MB </warning>
