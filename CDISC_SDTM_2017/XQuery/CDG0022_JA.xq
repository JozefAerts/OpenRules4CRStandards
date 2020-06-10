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

(: Rule CG0022: --LNKGRP present in another domain :)
(: Precondition: --LNKGRP present in a domain :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: need a function substring-after-last - see e.g. http://www.xqueryfunctions.com/xq/functx_substring-after-last.html :)
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: find all datasets  :)
(: let $base := '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
let $lnkgrp := 'LNKGRP'
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    (: get the domain name - value of the 'Domain' attribute :)
    let $domain := $itemgroupdef/@Domain
    (: and the dataset name (@Name attribute) :)
    let $itemgroupdefname := $itemgroupdef/@Name
    (: and get the filename and the corresponding document :)
    let $filename := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$filename))
    (: get the --LNKGRP variable(s) (by the OID) :)
    let $lnkgrpset := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,$lnkgrp)]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a 
    )
    (: $lnkgrpset now contains the OIDs of zero (often), one (sometimes), or more (never) variables :)
    for $lnkgrpoid in $lnkgrpset  (: iterate over them - although there usually will be only 0 or 1 :)
        let $lnkgrpname := $definedoc//odm:ItemDef[@OID=$lnkgrpoid]/@Name (: the full name of the --LNKGRP :)
        (: the rule states that there must be a --LNKGRP PRESENT in another domain, not that it need to be populated.
        Also see the answers to comment from the public review period - comment ID 31 and 32 :)
        (: iterate over all OTHER datasets and count the number of --LNKGRP variables :)
        (: TODO: this is not entirely correct, as it supposes that the OID of the LNKGRP variable ends-with 'LNKGRP' :)
        let $otherlnkgrp := $definedoc//odm:ItemGroupDef[not(@Name=$itemgroupdefname)][odm:ItemRef[ends-with(@ItemOID,$lnkgrp)]]
        (: if there are none, this means that the rule is violated that there must be SOME --LNKGRP in any other dataset/domain :)
        where count($otherlnkgrp = 0)
        return <error rule="CG0022" dataset="{data($itemgroupdefname)}" variable="{data($lnkgrpname)}" rulelastupdate="2017-02-04">A variable {data($lnkgrpname)} was found for the dataset {data($itemgroupdefname)} but no other datasets have a --LNKGRP variable</error>			
			