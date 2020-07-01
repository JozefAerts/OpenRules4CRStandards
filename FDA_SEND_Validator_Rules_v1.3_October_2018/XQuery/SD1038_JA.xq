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

(: Rule SD1038 - Non-unique value for TSSEQ variable within TSPARMCD - 
Sequence Number (TSSEQ) must have a  unique value for a given value of Trial Summary Parameter Short Name (TSPARMCD) within the domain,
i.e. combination of TSSEQ and TSPARMCD must be unique :)
(:can be made much more faster using "GROUP BY" :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: get the OID of the TSSEQ and TSPARMCD variables in the define.xml :)
let $tsseq := doc(concat($base,$define))//odm:ItemDef[@Name='TSSEQ']/@OID
let $tsparmcd := doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID
(: get the TS dataset :)
let $tsdatasetname := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/def:leaf/@xlink:href
let $tsdataset := concat($base,$tsdatasetname)
(: now iterate over the TS records :)
for $d in doc($tsdataset)//odm:ItemGroupData
    let $seqvalue := $d/odm:ItemData[@ItemOID=$tsseq]/@Value
    let $parmcdvalue := $d/odm:ItemData[@ItemOID=$tsparmcd]/@Value
    let $recnum := $d/@data:ItemGroupDataSeq
    (: and count the one with the (same) combination of TSSEQ and TSPARMCD in the dataset :)
    (: additional possibility to speed up: add [@data:ItemGroupDataSeq > $recnum] :)
    let $count := count(doc($tsdataset)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsseq and @Value=$seqvalue] and odm:ItemData[@ItemOID=$tsparmcd and @Value=$parmcdvalue]])
    where $count > 1
    return <error rule="SD1038" dataset="TS" rulelastupdate="2019-08-29" recordnumber="{data($recnum)}">Non-unique value for TSSEQ variable within TSPARMCD - combination of TSSEQ={data($seqvalue)} and TSPARMCD={data($parmcdvalue)} occurs {data($count)} times</error>
