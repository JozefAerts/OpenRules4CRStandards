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

(: Rule CDG0330 - Variable is in wrong order within domain: Order of variables should be as specified by CDISC standard
We must look into the SDTM specification itself, make a list (how do we deal with prefixes?) and then compare the list with the order in the define.xml.
Is it also possible (in a second step?) to compare the order of the variables in each record with that in the define.xml?
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
declare variable $datasetname external;
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: value-intersect function: returns the intersection of two sequences :)
declare function functx:value-intersect
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[.=$arg2])
 } ;
(: combines two sequences :)
declare function functx:value-union
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
  distinct-values(($arg1, $arg2))
 } ;
 
 (: This function compares two sequences in which the second is a subset of the first.
 If the order in both is the same, the function returns 'true', if the order is different, it returns 'false' :)
 declare function local:compare($sequence1, $sequence2) {
    let $new-list :=
      for $id in $sequence1
      where $id = $sequence2
      return $id
    return string-join($sequence2,'') eq string-join($new-list, '')
} ;
(: function replacing two subsequent dashes with the domain code :)
declare function local:replacedash($sequence,$domain) {
    for $v in $sequence
            return replace($v,'\-\-',$domain)
} ;

(: Identifiers for all classes :)
let $identifiers := ('STUDYID','DOMAIN','USUBJID','POOLID','SPDEVID','--SEQ','--GRPID',
    '--REFID','--SPID','--LNKID','--LNKGRP')
(: Timing variables for all classes :)
let $timingvars := ('VISITNUM','VISIT','VISITDY','TAETORD','EPOCH','--DTC','--STDTC','--ENDTC', '--DY','--STDY','--ENDY','--DUR','--TPT','--TPTNUM','--ELTM','--TPTREF','--RFTDTC','--STRF','--ENRF','--EVLINT','--EVINTX','--STRTPT','--STTPT','--ENRTPT','--ENTPT','--STINT','--ENINT','--DETECT')
let $dmvars := ('STUDYID','DOMAIN','USUBJID','SUBJID','RFSTDTC','RFENDTC','RFXSTDTC','RFXENDTC','RFICDTC','RFPENDTC','DTHDTC','DTHFL','SITEID','INVID','INVNAM','BRTHDTC','AGE','AGETXT','AGEU','SEX','RACE','ETHNIC','SPECIES','STRAIN','SBSTRAIN','ARMCD','ARM','ACTARMCD','ACTARM','SETCD','COUNTRY','DMDTC','DMDY')
(: variables for Interventions classes :) 
let $interventionvars := ('--TRT','--MODIFY','--DECOD','--MOOD','--CAT','--SCAT','--PRESP','--OCCUR','--STAT','--REASND','--INDC','--CLAS','--CLASCD','--DOSE','--DOSTXT','--DOSU','--DOSFRM','--DOSFRQ','--DOSTOT','--DOSRGM','--ROUTE','--LOT','--LOC','--LAT','--DIR','--PORTOT','--FAST','--PSTRG','--PSTRGU','--TRTV','--VAMT','--VAMTU','--ADJ')
(: variables for all Event classes :)
let $eventvars := ('--TERM','--MODIFY','--LLT','--LLTCD','--DECOD','--PTCD','--HLT','--HLTCD','--HLGT','--HLGTCD','--CAT','--SCAT','--PRESP','--OCCUR','--STAT','--REASND','--BODSYS','--BDSYCD','--SOC','--SOCCD','--LOC','--LAT','--DIR','--PORTOT','--PARTY','--PRTYID','--SEV','--SER','--ACN','--ACNOTH','--ACNDEV','--REL','--RELNST','--PATT','--OUT','--SCAN','--SCONG','--SDISAB','--SDTH','--SHOSP','--SLIFE','--SOD','--SMIE','--CONTRT','--TOX','--TOXGR')
let $findingvars := ('--TESTCD','--TEST','--MODIFY','--TSTDTL','--CAT','--SCAT','--POS','--BODSYS','--ORRES','--ORRESU','--ORNRLO','--ORNRHI','--STRESC','--STRESN','--STRESU','--STNRLO','--STNRHI','--STNRC','--NRIND','--RESCAT','--STAT','--REASND','--XFN','--NAM','--LOINC','--SPEC','--ANTREG','--SPCCND','--SPCUFL','--LOC','--LAT','--DIR','--PORTOT','--METHOD','--RUNID','--ANMETH','--LEAD','--CSTATE','--BLFL','--FAST','--DRVFL','--EVAL','--EVALID','--ACPTFL','--TOX','--TOXGR','--SEV','--DTHREL','--LLOQ','--ULOQ','--EXCLFL','--REASEX')
(: FA-domains: --OBJ - comes after --TEST :)
let $findingsaboutvars := ('--TESTCD','--TEST','--OBJ','--MODIFY','--TSTDTL','--CAT','--SCAT','--POS','--BODSYS','--ORRES','--ORRESU','--ORNRLO','--ORNRHI','--STRESC','--STRESN','--STRESU','--STNRLO','--STNRHI','--STNRC','--NRIND','--RESCAT','--STAT','--REASND','--XFN','--NAM','--LOINC','--SPEC','--ANTREG','--SPCCND','--SPCUFL','--LOC','--LAT','--DIR','--PORTOT','--METHOD','--RUNID','--ANMETH','--LEAD','--CSTATE','--BLFL','--FAST','--DRVFL','--EVAL','--EVALID','--ACPTFL','--TOX','--TOXGR','--SEV','--DTHREL','--LLOQ','--ULOQ','--EXCLFL','--REASEX') 
(: Special purpose: Comments (CO) domain - 
 Remark that we do not allow for COVAL1, COVAL2, ... as we are using Dataset-XML 
 which doesn't have the 200 character limitation :)
let $commentvars := ('STUDYID','DOMAIN','RDOMAIN','USUBJID','POOLID','COSEQ','IDVAR','IDVARVAL','COREF','COVAL','COEVAL','CODTC')
(: Subject Elements (SE) :)
let $subjectelementsvar := ('STUDYID','DOMAIN','USUBJID','SESEQ','ETCD','ELEMENT','SESTDTC','SEENDTC','TAETORD','EPOCH','SEUPDES')
(: Subject Visits (SV) :)
let $subjectvisitsvar := ('STUDYID','DOMAIN','USUBJID','VISITNUM','VISIT','VISITDY','SVSTDTC','SVENDTC','SVSTDY','SVENDY','SVUPDES')
(: Trial Design datasets :)
(: Trial Elements (TE) :)
let $trialelementvars := ('STUDYID','DOMAIN','ETCD','ELEMENT','TESTRL','TEENRL','TEDUR')
(: Trial Arms :)
let $trialarmvars := ('STUDYID','DOMAIN','ARMCD','ARM','TAETORD','ETCD','ELEMENT','TABRANCH','TATRANS','EPOCH')
(: Trial Visits (TV) :)
let $trialvisitvars := ('STUDYID','DOMAIN','VISITNUM','VISIT','VISITDY','ARMCD','ARM','TVSTRL','TVENRL')
(: Trial Sets (TX) :)
let $trialsetvars := ('STUDYID','DOMAIN','SETCD','SET','TXSEQ','TXPARMCD','TXPARM','TXVAL')
(: Trial Inclusion/Exclusion Criteria (TI) :)
let $trialievars := ('STUDYID','DOMAIN','IETESTCD','IETEST','IECAT','IESCAT','TIRL','TIVERS')
(: Trial Summary (TS) :)
let $trialsummaryvars := ('STUDYID','DOMAIN','TSSEQ','TSGRPID','TSPARMCD','TSPARM','TSVAL','TSVALNF','TSVALCD','TSVCDREF','TSVCDVER')
(: Trial Disease Assessments (TD) :)
let $trialdiseasevars := ('STUDYID','DOMAIN','TDORDER','TDANCVAR','TDSTOFF','TDTGTPAI','TDMINPAI','TDMAXPAI','TDNUMRPT')
(: Related Records (RELREC) :)
let $relrecvars := ('STUDYID','RDOMAIN','USUBJID','APID','POOLID','IDVAR','IDVARVAL','RELTYPE','RELID')
(: supplemental qualifiers (SUPPxx)  :)
let $suppqualvars := ('STUDYID','RDOMAIN','USUBJID','APID','POOLID','IDVAR','IDVARVAL','QNAM','QLABEL','QVAL','QORIG','QEVAL')
(: Get the define.xml file :)
(: let $base:= '/db/fda_submissions/cdiscpilot01/' :)
(: let $define := 'define_2_0.xml' :)
let $datasetdoc := doc(concat($base,$define))
(: iterate over all ItemGroupDef elements in define.xml for the provided dataset name :)
for $dataset in $datasetdoc//odm:ItemGroupDef[@Name=$datasetname]
    (: get the 2-letter domain (except for SUPPQUAL, RELREC, ...)
        as we need it to replace the "--" by the domain code
    :)
    (: Get the domain name and class :)
    (: let $domaincode := $dataset/@Name :)
    (: take care of the case that the Domain attribute is absent :)
    let $domaincode := if ($dataset/@Domain) then $dataset/@Domain
    	else $dataset/@Name
    let $domainclass := $dataset/@def:Class
    let $dsname := $dataset/@Name
    (: iterate over the ItemRef elements and get the OID - then transform it to the Name
    make an array out of it :)
    let $vararray := (
    for $itemref in $dataset/odm:ItemRef
        (: Attention - we need to exclude non-standard variables (NSVs) :)
        let $itemrefoid := $itemref[not(starts-with(upper-case(@Role),'SUPPLEMENTAL'))]/@ItemOID
        (: Get the name of the variable from the corresponding ItemDef :)
        let $varname := doc(concat($base,$define))//odm:ItemDef[@OID=$itemrefoid]/@Name
        return $varname
    )
    (: now create the array to compare with - we need to replace any '--' by the domain code :)
    (: replace any dashes in the variable names by the domain code :)
    let $identifiers := local:replacedash($identifiers,$domaincode)
    let $timingvars := local:replacedash($timingvars,$domaincode)
    let $interventionvars := local:replacedash($interventionvars,$domaincode)
    let $eventvars := local:replacedash($eventvars,$domaincode)
    let $findingvars := local:replacedash($findingvars,$domaincode)
    (: combine all variables: identifiers, class-specific variables and timing variables 
    into a single sequence :)
    let $standardvars := (
        if ($domaincode = 'DM') then $dmvars
        else if($domaincode = 'CO') then $commentvars
        else if($domaincode = 'SE') then $subjectelementsvar
        else if($domaincode = 'SV') then $subjectvisitsvar
        else if($domaincode = 'TV') then $trialvisitvars
        (: Trial Design datasets :)
        else if($domaincode = 'TE') then $trialelementvars
        else if($domaincode = 'TA') then $trialarmvars
        else if($domaincode = 'TX') then $trialsetvars
        else if($domaincode = 'TI') then $trialievars
        else if($domaincode = 'TS') then $trialsummaryvars
        else if($domaincode = 'TD') then $trialdiseasevars
        else if(starts-with($domaincode,'SUPP')) then $suppqualvars
        (: Related Records dataset :)
        else if($domaincode = 'RELREC') then $relrecvars
        else if (upper-case($domainclass) = 'INTERVENTIONS' ) then
            functx:value-union(functx:value-union($identifiers,$interventionvars),$timingvars)
        else if (upper-case($domainclass) = 'EVENTS') then
            functx:value-union(functx:value-union($identifiers,$eventvars),$timingvars)
        else if (upper-case($domainclass) = 'FINDINGS') then
            functx:value-union(functx:value-union($identifiers,$findingvars),$timingvars)    
        else ()
    )
    (: if 'false' is returned by local:compare then the order is incorrect :)
    where local:compare($standardvars,$vararray) = false()
    return <error rule="CDG0330" dataset="{data($datasetname)}" rulelastupdate="2019-08-12">{data($datasetname)} - domain {data($domaincode)}: Invalid order of variables in define.xml - found: {data($vararray)}
    - expected: {data($standardvars)}</error>			
		
		