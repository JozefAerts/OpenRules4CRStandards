This repository is a repository of free and open validation rules for clinical research standards (CDISC,FDA,PMDA).

Rules can be developed and added in the languages R, SAS, XQuery and Schematron.

A set of "best practice rules" for developing and submitting such rules will be published here soon.

Organization of the repository
------------------------------

The repository is organized per organization and standard and version of the rules. For example:

- the folder "FDA_SDTM_Validator_Rules_v1.3_October_2018" contains implementations of the validation rules for the SDTM standard published by the FDA in October 2018
- the folder "CDISC_SDTM_Validation_Rules_1_1_May_2020" contains implementations of the validation rules for the SDTM standard published by CDISC in May 2020
- the folder "PMDA_ADaM_Validation_Rules_v2.0_2019_09_27" contains implementations of the validation rules for the PMDA standard published by the PMDA in September 2019

It will not be the goal of having all rules complete for all standards and organization and versions, 
emphasis will be on the newest versions of the rules.

In each folder, you will find a subfolder "R", "SAS" and "XQuery". 
These are meant to contain rule scripts in the R, SAS and XQuery language respectively

Best practices for development of rules
---------------------------------------

- When possible, one rule implementation per file
- Name your file in such a way that it is immediately clear about what rule it is, and who the developer was, for example "CG0006_JA.xq" for CDISC rule CG0006 
("--DY calculated as per the study day algorithm must be a non-zero integer value") developed by Jozef Aerts
- There can be more versions for each rule implementation. Not only because of different authors, but also because of different use cases.
For example, the script "CG0006-SD_JA" is an alternative implementation of CDISC-SDTM rule CG0006 that only expects a single dataset instead of iterating over all datasets
- Please add a "license" comment at the top of your script, i.e. make a declaration which open source license applies. For example, the text of the Apache-2 license.
- When possible, use (information from) the define.xml file. For example, for validating whether a date is a valid date, your script may first look up in the define.xml file
whether the declared datatype for the variable involved is "date", "dateTime", partialDate", etc..
- Feel free to use RESTful web services in your script where appropriate and useful. Examples are the CDISC Library API (https://www.cdisc.org/cdisc-library),
one of the XML4Pharma RESTful web services (http://xml4pharmaserver.com/WebServices/index.html) or one of the many NLM (US National Library of Medicine) RESTful web services.
- Please add a lot comments in your scripts, so that users can understand how your script works and can adapt it for their own purposes.