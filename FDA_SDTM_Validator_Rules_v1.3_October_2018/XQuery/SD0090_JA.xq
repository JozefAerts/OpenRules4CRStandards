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
		
(: Rule SD0090 - AESDTH is not 'Y', when AEOUT='FATAL':
Results in Death (AEDTH) should equal 'Y', when Outcome of Adverse Event (AEOUT)  is 'FATAL'
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace def21 = "http://www.cdisc.org/ns/def/v2.1";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
declare variable $defineversion external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Get the AE dataset(s) :)
for $aedataset in $definedoc//odm:ItemGroupDef[@Name='AE']
    let $aename := $aedataset/@Name
    let $aedatasetname := ( 
		if($defineversion = '2.1') then $aedataset/def21:leaf/@xlink:href
		else $aedataset/def:leaf/@xlink:href
	)
    let $aedatasetlocation := concat($base,$aedatasetname)
    (: and get the OID of AESDTH and AEOUT :)
    let $aesdthoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AESDTH']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    let $aeoutoid := (
        for $a in $definedoc//odm:ItemDef[@Name='AEOUT']/@OID 
        where $a = $definedoc//odm:ItemGroupDef[@Name=$aename]/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all records that have AEOUT='FATAL' :)
    for $record in doc($aedatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$aeoutoid and @Value='FATAL']]
        let $recnum := $record/@data:ItemGroupDataSeq
        let $aesdthvalue := $record/odm:ItemData[@ItemOID=$aesdthoid]/@Value
        (: AEDTH must be 'Y' :)
        let $recnum := $record/@data:ItemGroupDataSeq
        where not($aesdthvalue='Y')
        return <error rule="SD0090" dataset="AE" variable="AEDTH" rulelastupdate="2020-08-08" recordnumber="{data($recnum)}">AESDTH is not 'Y', when AEOUT='FATAL', value for AESDTH found is '{data($aesdthvalue)}'</error>
