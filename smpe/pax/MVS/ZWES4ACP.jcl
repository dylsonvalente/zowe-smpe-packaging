//ZWES4ACP JOB <job parameters>
//*
//* This program and the accompanying materials are made available
//* under the terms of the Eclipse Public License v2.0 which
//* accompanies this distribution, and is available at
//* https://www.eclipse.org/legal/epl-v20.html
//*
//* SPDX-License-Identifier: EPL-2.0
//*
//* 5698-ZWE Copyright Contributors to the Zowe Project. 2019, [YEAR]
//*
//********************************************************************
//*
//* This JCL will ACCEPT a service SYSMOD (PTF, APAR, USERMOD).
//*
//*
//* CAUTION: This is neither a JCL procedure nor a complete job.
//* Before using this job step, you will have to make the following
//* modifications:
//*
//* 1) Add the job parameters to meet your system requirements.
//*
//* 2) Change #csihlq to the high level qualifier for the global zone
//*    of the CSI.
//*
//* 3) Change #dzone to your CSI distribution zone name.
//*
//* 4) Change #sysmod to the name of the SYSMOD to be accepted.
//*
//* Note(s):
//*
//* 1. If the service SYSMOD has embedded HOLDDATA, you will have to
//*    use the BYPASS option for tha ACCEPT to succeed. Read the
//*    provided HOLDDATA (in the job output) before doing so.
//*    A sample BYPASS option is provided that bypasses the most
//*    common reason IDs (HOLDSYS, HOLDERROR).
//*
//* 2. This job utilizes JCL variables inside inline text, which
//*    requires z/OS 2.1 or higher. When using an older z/OS level,
//*    - Comment out the EXPORT SYMLIST statement
//*    - Remove ",SYMBOLS=JCLONLY" from the DD definitions that
//*      utilize inline JCL variables
//*    - Replace the following variables with their actual value:
//*      - step ACEPTCHK, DD SMPCNTL, variable &ZONE
//*      - step ACEPTCHK, DD SMPCNTL, variable &SYSMOD
//*      - step ACCEPT, DD SMPCNTL, variable &ZONE
//*      - step ACCEPT, DD SMPCNTL, variable &SYSMOD
//*
//* 3. This job should complete with a return code 0.
//*
//********************************************************************
//         EXPORT SYMLIST=(ZONE,SYSMOD)
//*
//         SET SYSMOD=#sysmod
//         SET ZONE=#dzone
//         SET CSIHLQ=#csihlq
//*
//ACEPTCHK EXEC PGM=GIMSMP,REGION=0M,COND=(4,LT)
//SMPCSI   DD DISP=OLD,DSN=&CSIHLQ..CSI
//SMPCNTL  DD *,SYMBOLS=JCLONLY
   SET BOUNDARY(&ZONE) .
   ACCEPT REDO COMPRESS(ALL)
          CHECK
          SELECT(
   &SYSMOD
   ) .
//*
//ACCEPT   EXEC PGM=GIMSMP,REGION=0M,COND=(4,LT)
//SMPCSI   DD DISP=OLD,DSN=&CSIHLQ..CSI
//SMPCNTL  DD *,SYMBOLS=JCLONLY
   SET BOUNDARY(&ZONE) .
   ACCEPT REDO COMPRESS(ALL)
        /*BYPASS(HOLDSYS,HOLDERROR)*/
          SELECT(
   &SYSMOD
   ) .
//*


