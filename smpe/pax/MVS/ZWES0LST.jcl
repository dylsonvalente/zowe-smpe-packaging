//ZWES0LST JOB <job parameters>
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
//* This JCL will list all SYSMODs for a given zone.
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
//* 3) Change #tzone to your CSI target zone name.
//*
//* 4) Change #dzone to your CSI distribution zone name.
//*
//* 5) Uncomment the desired SET ZONE= statement and comment out
//*    the other ones. The name of the SET statement (ACCEPT, APPLY, 
//*    RECEIVE) indicates what type of information is in that zone.
//*
//* Note(s):
//*
//* 1. This job utilizes JCL variables inside inline text, which
//*    requires z/OS 2.1 or higher. When using an older z/OS level,
//*    - Comment out the EXPORT SYMLIST statement
//*    - Remove ",SYMBOLS=JCLONLY" from the DD definitions that 
//*      utilize inline JCL variables
//*    - Replace the following variables with their actual value:
//*      - step LIST, DD SMPCNTL, variable &ZONE
//*
//* 2. This job should complete with a return code 0.
//*
//********************************************************************
//         EXPORT SYMLIST=(ZONE)
//*
//*ACCEPT   SET ZONE=#dzone
//*APPLY    SET ZONE=#tzone
//RECEIVE  SET ZONE=GLOBAL
//*
//LIST     EXEC PGM=GIMSMP,REGION=0M,COND=(4,LT)
//SMPCSI   DD DISP=OLD,DSN=#csihlq.CSI
//SMPCNTL  DD *,SYMBOLS=JCLONLY
   SET BOUNDARY(&ZONE) .
   LIST FUNCTIONS PTF APAR USERMOD
   .
//*
