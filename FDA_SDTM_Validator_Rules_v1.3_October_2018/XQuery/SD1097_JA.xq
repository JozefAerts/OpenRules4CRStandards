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

(: Rule SD1097 - No Treatment Emergent info for Adverse Event: A treatment-emergent flag should be included in SUPPAE according to SDTM IG v3.1.2 #8.4.3 :)
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
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: look for a SUPPAE dataset and the AE dataset itself :)
let $suppaedataset := $definedoc//odm:ItemGroupDef[@Name='SUPPAE']
let $aedataset := $definedoc//odm:ItemGroupDef[@Name='AE']
(: get the OID of the QVAL SUPPAE variabke :)
let $suppaeqnamoid := (
    for $a in $definedoc//odm:ItemDef[@Name='QVAL']/@OID
        where $a = $definedoc//odm:ItemGroupDef[@Name='SUPPAE']/odm:ItemRef/@ItemOID
        return $a
)
(: now that we have the OID of the QVAL, check whether there is a ValueList attached :)
let $qvalvaluelistoid := (
	if ($defineversion = '2.1') then $definedoc//odm:ItemDef[@OID=$suppaeqnamoid]/def21:ValueListRef/@ValueListOID
	else $definedoc//odm:ItemDef[@OID=$suppaeqnamoid]/def:ValueListRef/@ValueListOID
)
(: and look for a "AETRTEM" in it :)
let $aetrtemoid := (
	if($defineversion = '2.1') then 
		 for $a in $definedoc//odm:ItemDef[@Name='AETRTEM']/@OID
			where $a = $definedoc//def21:ValueListDef[@OID=$qvalvaluelistoid]/odm:ItemRef/@ItemOID
			return $a
	else 
		for $a in $definedoc//odm:ItemDef[@Name='AETRTEM']/@OID
			where $a = $definedoc//def:ValueListDef[@OID=$qvalvaluelistoid]/odm:ItemRef/@ItemOID
			return $a
)
(: and check whether the corresponding ItemDef exists :)
let $aetrtemdef := $definedoc//odm:ItemDef[@OID=$aetrtemoid]
(: when absent, report an error :)
where not($aetrtemdef)
return <warning rule="SD1097" dataset="SUPPAE" rulelastupdate="2020-08-08">No Treatment Emergent info for Adverse Event - SUPPAE QVAL does not have an entry AETRTEM in ValueList</warning>
