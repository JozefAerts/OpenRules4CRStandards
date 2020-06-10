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

(: Rule CG0246 - TA,TE,SE - ETCD value length <= 8 :) 
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
let $definedoc := doc(concat($base,$define))
(: Get the TA,TE,SE datasets :)
for $datasetdef in $definedoc//odm:ItemGroupDef[@Name='TA' or @Name='TE' or @Name='SE']
let $name := $datasetdef/@Name
    let $datasetname := $datasetdef/def:leaf/@xlink:href
    let $datasetdoc := doc(concat($base,$datasetname))
    (: also need to find out the OID of ETCD :)
    let $etcdoid := (
            for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
            where $a = $datasetdef/odm:ItemRef/@ItemOID
            return $a
    )
    (: iterate over all records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: Get the ETCD value :)
        let $etcdvalue := $record/odm:ItemData[@ItemOID=$etcdoid]/@Value
        (: and check whether more than 8 characters :)
        where string-length($etcdvalue) > 8
        return <error rule="CG0246" dataset="{data($name)}" variable="ETCD" rulelastupdate="2017-02-25" recordnumber="{data($recnum)}">Invalid value for ETCD dataset {data($name)} - Value {data($etcdvalue)} has more than 8 characters</error>
			
		
		