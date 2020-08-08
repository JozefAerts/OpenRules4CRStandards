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
	
(: Rule SD1077:  EPOCH should be included for clinical subject-level observations (e.g., adverse events, laboratory, concomitant medications, exposure, and vital signs).
What the hell does "e.g." mean in a rule? 
We will apply it to all datasets except for SUPPQUAL, RELREC, DM, Tx (trial design) and MH (where it just doesn't make sense) 
and for SE and SV :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/' 
let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: iterate over all the dataset definitions in the define.xml, 
 except for DM, SUPPQUAL, RELREC, and the trial design domains :)
for $datasetdef in $definedoc//odm:ItemGroupDef[not(@Name='DM' or @Name='TS' or @Name='TA' or @Name='TE' or @Name='TV' or @Name='TD' or @Name='TI' or @Domain='MH' or @Name='SV' or @Name='SE' or @Name='RELREC' or starts-with(@Name,'SUPP'))]
    (: get the dataset name :)
    let $name := $datasetdef/@Name
    (: get whether there is an EPOCH variable :)
    let $epochoid := (
        for $a in $definedoc//odm:ItemDef[@Name='EPOCH']/@OID 
        where $a = $datasetdef/odm:ItemRef/@ItemOID
        return $a
    )
    (: if there is no EPOCH variable defined, give an error :)
    where not($epochoid)
    return <error rule="SD1077" dataset="{data($name)}" variable="EPOCH" rulelastupdate="2020-08-08">FDA expected variable EPOCH is not found in dataset '{data($name)}'</error>

