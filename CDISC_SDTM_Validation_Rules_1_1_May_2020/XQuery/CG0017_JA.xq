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

(: Rule CG0017 - Split dataset names length > 2 and <= 4. 
P.S.: What about splitted FAxx domains? For example, FAAE1, FAAE2 ... ? :)
(: 'Split dataset names can be up to four characters in length.  For example, if splitting by --CAT, then dataset names would be the domain name plus up to two additional characters (e.g., QS36 for SF-36). 
If splitting Findings About by parent domain, then the dataset name would be the domain name plus the two-character domain code describing the parent domain code (e.g., FACM).
:)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: iterate over all datasets in the define.xml that have a 'Domain' attribute
 and that are not SUPPxx (Supplemental Qualifiers) datasets :)
for $itemgroup in doc(concat($base,$define))//odm:ItemGroupDef[@Domain and not(starts-with(@Name,'SUPP'))]
    (: get the domain name - value of the 'Domain' attribute :)
    let $domain := $itemgroup/@Domain
    (: and the dataset name (@Name attribute) :)
    let $name := $itemgroup/@Name
    (: and get the filename :)
    let $filename := $itemgroup/def:leaf/@xlink:href
    (: get the position of the current ItemGroupDef in the series :)
    let $pos := $itemgroup/position()
    (: get all the ItemGroupDefs with the same value for the 'Domain' attribute
    If so, this means that the dataset is a 'splitted' dataset. 
    P.S. There currently is no other way to find out :)
    let $count := count(doc(concat($base,$define))//odm:ItemGroupDef[@Domain=$domain])
    (: in case there is more than one such dataset, the prefix (part before the dot)
    MUST have MORE than two characters (e.g. qscs.xpt) and no more than 4 characters :)
    let $numchars := string-length(substring-before($filename,'.'))
    where $count > 1 and ($numchars < 3 or $numchars > 4)
        return <error rule="CG0017" dataset="{data($name)}" rulelastupdate="2020-06-11">Split dataset {data($name)} has a dataset/file name '{data($filename)}' with less than 3 or more than 4 characters</error>			
		
	