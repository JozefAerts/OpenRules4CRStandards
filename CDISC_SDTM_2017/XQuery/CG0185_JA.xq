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

(: Rule CG0185 - When Numeric scale used then LBTOXGR is a numeric value :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function counting the number of matches for a pattern 
 See http://www.xqueryfunctions.com/xq/alpha.html :)
declare function functx:number-of-matches
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer {
   count(tokenize($arg,$pattern)) - 1
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the LB datasets (just in case it is splitted) :)
for $lbdatasetdef in $definedoc//odm:ItemGroupDef[starts-with(@Name,'LB') or @Domain='LB']
    let $name := $lbdatasetdef/@Name
    (: get the OID of the LBTOXGR variable :)
    let $lbtoxgroid := (
        for $a in $definedoc//odm:ItemDef[@Name='LBTOXGR']/@OID 
        where $a = $lbdatasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: get the dataset location :)
    let $datasetlocation := $lbdatasetdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetlocation))
    (: iterate over all records in the dataset that have a value for LBTOXGR :)
    for $record in $datasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$lbtoxgroid and @Value]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of LBTOXGR (as string) :)
        let $lbtoxgr := $record/odm:ItemData[@ItemOID=$lbtoxgroid]/@Value
        (: give an error when the value is NOT a number, but does contain a number.
        The function functx:number-of-matches($lbtoxgr,'\d') counts the number of decimal characters :)
        where not($lbtoxgr castable as xs:double) and functx:number-of-matches($lbtoxgr,'\d') > 0
        return <error rule="CG0185" dataset="{data($name)}" variable="LBTOXGR" rulelastupdate="2017-02-21" recordnumber="{data($recnum)}">Value of LBTOXGR={data($lbtoxgr)} represents a numeric scale but is not a complete number</error>			
		
		