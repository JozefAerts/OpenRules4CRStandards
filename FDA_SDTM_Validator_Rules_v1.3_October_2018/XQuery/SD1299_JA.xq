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

(: Rule CG0220 - INTERVENTIONS, EVENTS, FINDINGS - At least one timing variable present in dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: This is the list of timing variables for SDTM 1.4. 
Dashes will later be replaced by the domain name :)
let $timingvars := ('VISITNUM','VISIT','VISITDY','TAETORD','EPOCH','--DTC','--STDTC','--ENDTC','--DY','--STDY','--ENDY', 
'--DUR','--TPT','--TPTNUM','--ELTM','--TPTREF','--RFTDTC','--STRF','--ENRF','--EVLINT','--EVINTX','--STRTPT','--STTPT',
'--ENRTPT','--ENTPT','--STINT','--ENINT','--DETECT')
(: iterate over all INTERVENTIONS, EVENTS and FINDINGS dataset definitions, except for IE and SC :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS' or upper-case(@def:Class)='EVENTS' or upper-case(@def:Class)='FINDINGS' 
		or upper-case(./def21:Class/@Name)='INTERVENTIONS' or upper-case(./def21:Class/@Name)='EVENTS' or upper-case(./def21:Class/@Name)='FINDINGS'][not(@Name='SC' or @Name='IE')]
    (: get the domain name and dataset name  :)
    let $name := $itemgroupdef/@Name
    let $domain := $itemgroupdef/@Domain
    (: generate the prefix - take either the domain name (preferred), 
    or the first 2 characters of the dataset name in case the domain name is missing :)
    let $prefix := (
        if($domain) then $domain
        else substring($name,1,2)
    )
    (: in the set of timing variables, replace the -- by the prefix :)
    let $timingvarsdomain := (
        for $s in $timingvars
            let $newtimingvar := (
                if(starts-with($s,'--')) then concat($prefix,substring($s,3))
                else $s
            )
            return $newtimingvar
    )
    (: return <test>{data($timingvarsdomain)}</test> :)
    (: create a list of the variables for this dataset :)
    let $datasetvars := (
        for $a in $itemgroupdef/odm:ItemRef/@ItemOID
        return $definedoc//odm:ItemDef[@OID=$a]/@Name
    )
    (: return <test>{data($datasetvars)}</test> :)
    (: count the number of variables in the intersection of allowed timing variables and the variables in this dataset :)
    let $intersection := distinct-values($timingvarsdomain[.=$datasetvars])
    (: return <test>{data($intersection)}</test> :)
    let $count := count($intersection)
    (: if the count of items in the intersection = 0, there is no timing variable in the dataset :)
    where $count=0
    return <error rule="SD1299" dataset="{data($name)}" rulelastupdate="2020-08-08">No timing variables have been defined in dataset {data($name)}</error>			
	