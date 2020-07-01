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

(: Rule SD1063 - Dataset is not present in define.xml :)
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: need a function substring-after-last - see e.g. http://www.xqueryfunctions.com/xq/functx_substring-after-last.html :)

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
(: function "substring-after-last occurrence of a given delimiter :)
declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

for $doc in collection($base)
    (: get the filename :)
    let $filename := functx:substring-after-last(document-uri($doc),'/')
    (: and exclude the define.xml itself :)
    where $filename != $define and not(ends-with($filename,'.xsl')) (: exclude the define.xml doc itself, as well as any stylesheets :)
    (: now check whether it is referenced in the define.xml :)
    and not(doc(concat($base,$define))//odm:ItemGroupDef/def:leaf[@xlink:href=$filename])
    return <warning rule="SD1063" rulelastupdate="2019-08-17">Dataset {data($filename)} is not present in define file {data($define)} </warning>    
