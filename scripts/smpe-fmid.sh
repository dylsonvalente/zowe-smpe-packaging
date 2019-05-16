#!/bin/sh
#######################################################################
# This program and the accompanying materials are made available
# under the terms of the Eclipse Public License v2.0 which
# accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# 5698-ZWE Copyright Contributors to the Zowe Project. 2019, 2019
#######################################################################

#% package prepared product as base FMID (++FUNCTION)
#%
#% -?                 show this help message
#% -c smpe.yaml       use the specified config file
#% -d                 enable debug messages
#%
#% -c is required

prefix=ZWE                     # product prefix
parts=parts.txt                # parts known by SMP/E
allocScript=allocate-dataset.sh  # script to allocate data set
cfgScript=get-config.sh        # script to read smpe.yaml config data
here=$(dirname $0)             # script location
me=$(basename $0)              # script name
#debug=-d                      # -d or null, -d triggers early debug
#IgNoRe_ErRoR=1                # no exit on error when not null  #debug
#set -x                                                          #debug

test "$debug" && echo
test "$debug" && echo "> $me $@"

# ---------------------------------------------------------------------
# --- create & populate rel files
# ---------------------------------------------------------------------
function _relFiles
{
test "$debug" && echo
test "$debug" && echo "> _relFiles $@"

# TODO delete refile before copy

# F1
list=$(awk '/^S'$prefix'SAMP/{print $2}' $log/$parts \
     | grep -e ^${prefix}[[:digit:]] -e ^${prefix}MKDIR$)
_copyMvsMvs S${prefix}SAMP F1 "FB" "80" "PO" "10,2"

# F2
list=$(awk '/^S'$prefix'SAMP/{print $2}' $log/$parts \
     | grep -v ^${prefix}[[:digit:]] | grep -v ^${prefix}MKDIR$)
_copyMvsMvs S${prefix}SAMP F2 "FB" "80" "PO" "10,2"

# F3
list=$(awk '/^S'$prefix'AUTH/{print $2}' $log/$parts)
_copyMvsMvs S${prefix}AUTH F3 "U" "**" "PO" "10,2"

# F4
list=$(awk '/^S'$prefix'ZFS/{print $2}' $log/$parts \
     | grep -v ^${prefix}PAX)
_copyMvsMvs S${prefix}ZFS F4 "VB" "6995" "PO" "7500,750"

list=$(ls $ussI)
_copyUssMvs $ussI F4 "VB" "6995" "PO" "7500,750"

test "$debug" && echo "< _relFiles"
}    # _relFiles


# ---------------------------------------------------------------------
# --- create SMPMCS
# ---------------------------------------------------------------------
function _smpmcs
{
test "$debug" && echo
test "$debug" && echo "> _smpmcs $@"

echo "-- create SMPMCS"

file="${ROOT}/../SMPMCS.txt"
dsn="${HLQ}.SMPMCS"

year=$(date '+%Y')                                               # YYYY
test "$debug" && year=$year
julian=$(date +%Y%j)                                          # YYYYjjj
test "$debug" && julian=$julian

# validate/create target data set
$here/$allocScript $dsn "FB" "80" "PS" "1,1"
# returns 0 for OK, 1 for DCB mismatch, 2 for not pds(e), 8 for error
rc=$?
if test $rc -eq 0
then
  # customize SMPMCS
  _cmd --repl $file.new sed \
    "s/\[FMID\]/$FMID/g;s/\[YEAR\]/$year/g;s/\[DATE\]/$julian/g" \
    $file
  # move the customized file
  _cmd mv $file.new "//'$dsn'"
  
  # TODO SMPMCS SUP existing service

elif test $rc -eq 1
then
  echo "** ERROR $me data set $dsn exists with wrong DCB"
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
else
  # Error details already reported
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
fi    #

test "$debug" && echo "< _smpmcs"
}    # _smpmcs


# ---------------------------------------------------------------------
# --- copy MVS members defined in $list to specified data set
# $1: input data set low level qualifier
# $2: output data set low level qualifier
# $3: record format; {FB | U | VB}
# $4: logical record length, use ** for RECFM(U)
# $5: data set organisation; {PO | PS}
# $6: space in tracks; primary[,secondary]
# ---------------------------------------------------------------------
function _copyMvsMvs
{
test "$debug" && echo
test "$debug" && echo "> _copyMvsMvs $@"

from="${mvsI}.$1"
relFile="${HLQ}.$2"

echo "-- populate $2 with $1"

# validate/create target data set
$here/$allocScript $relFile "$3" "$4" "$5" "$6"
# returns 0 for OK, 1 for DCB mismatch, 2 for not pds(e), 8 for error
rc=$?
if test $rc -eq 0
then
  for member in $list
  do
    test "$debug" && echo member=$member
    
    # TODO test if $from($member) exists
    
    unset X
    test "$3" = "U" && X="-X"
    # cp -X requires z/OS V2R2 UA96711, z/OS V2R3 UA96707 (August 2018)
    _cmd cp $X "//'$from($member)'" "//'$relFile($member)'" 
    
    # TODO build SMPMCS data
    
  done    # for file
elif test $rc -eq 1
then
  echo "** ERROR $me data set $relFile exists with wrong DCB"
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
else
  # Error details already reported
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
fi    #

test "$debug" && echo "< _copyMvsMvs"
}    # _copyMvsMvs

# ---------------------------------------------------------------------
# --- copy USS files defined in $list to specified data set
# $1: input path
# $2: output data set low level qualifier
# $3: record format; {FB | U | VB}
# $4: logical record length, use ** for RECFM(U)
# $5: data set organisation; {PO | PS}
# $6: space in tracks; primary[,secondary]
# ---------------------------------------------------------------------
function _copyUssMvs
{
test "$debug" && echo
test "$debug" && echo "> _copyUssMvs $@"

from="$1"
relFile="${HLQ}.$2"

echo "-- populate $2 with $1"

# validate/create target data set
$here/$allocScript $relFile "$3" "$4" "$5" "$6"
# returns 0 for OK, 1 for DCB mismatch, 2 for not pds(e), 8 for error
rc=$?
if test $rc -eq 0
then
for file in $list
  do
    test "$debug" && echo file=$file
    if test ! -f "$from/$file" -o ! -r "$from/$file"
    then
      echo "** ERROR $me cannot access $file"
      echo "ls -ld \"$from/$file\""; ls -ld "$from/$file"
      test ! "$IgNoRe_ErRoR" && exit 8                           # EXIT
    fi    #
    
    unset X
    test "$3" = "U" && X="-X"
    # cp -X requires z/OS V2R2 UA96711, z/OS V2R3 UA96707 (August 2018)
    _cmd cp $X "$from/$file" "//'$relFile($file)'" 

    # TODO build SMPMCS data
    
  done    # for file
elif test $rc -eq 1
then
  echo "** ERROR $me data set $relFile exists with wrong DCB"
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
else
  # Error details already reported
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
fi    #

test "$debug" && echo "< _copyUssMvs"
}    # _copyUssMvs
# ---------------------------------------------------------------------
# --- show & execute command, and bail with message on error
#     stderr is routed to stdout to preserve the order of messages
# $1: if --null then trash stdout, parm is removed when present
# $1: if --save then append stdout to $2, parms are removed when present
# $1: if --repl then save stdout to $2, parms are removed when present
# $2: if $1 = --save or --repl then target receiving stdout
# $@: command with arguments to execute
# ---------------------------------------------------------------------
function _cmd
{
test "$debug" && echo
if test "$1" = "--null"
then         # stdout -> null, stderr -> stdout (without going to null)
  shift
  test "$debug" && echo "$@ 2>&1 >/dev/null"
                         $@ 2>&1 >/dev/null
elif test "$1" = "--save"
then         # stdout -> >>$2, stderr -> stdout (without going to $2)
  sAvE=$2
  shift 2
  test "$debug" && echo "$@ 2>&1 >> $sAvE"
                         $@ 2>&1 >> $sAvE
elif test "$1" = "--repl"
then         # stdout -> >$2, stderr -> stdout (without going to $2)
  sAvE=$2
  shift 2
  test "$debug" && echo "$@ 2>&1 > $sAvE"
                         $@ 2>&1 > $sAvE
else         # stderr -> stdout, caller can add >/dev/null to trash all
  test "$debug" && echo "$@ 2>&1"
                         $@ 2>&1
fi    #
sTaTuS=$?
if test $sTaTuS -ne 0
then
  echo "** ERROR $me '$@' ended with status $sTaTuS"
  test ! "$IgNoRe_ErRoR" && exit 8                               # EXIT
fi    #
}    # _cmd

# ---------------------------------------------------------------------
# --- display script usage information
# ---------------------------------------------------------------------
function _displayUsage
{
echo " "
echo " $me"
sed -n 's/^#%//p' $(whence $0)
echo " "
}    # _displayUsage

# ---------------------------------------------------------------------
# --- main --- main --- main --- main --- main --- main --- main ---
# ---------------------------------------------------------------------
function main { }     # dummy function to simplify program flow parsing

# misc setup
_EDC_ADD_ERRNO2=1                               # show details on error
unset ENV             # just in case, as it can cause unexpected output
_cmd umask 0022                                  # similar to chmod 755

echo; echo "-- $me - start $(date)"
echo "-- startup arguments: $@"

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# clear input variables
unset YAML in
# do NOT unset debug

# get startup arguments
while getopts c:i:?d opt
do case "$opt" in
  c)   YAML="$OPTARG";;
  d)   debug="-d";;
  [?]) _displayUsage
       test $opt = '?' || echo "** ERROR faulty startup argument: $@"
       test ! "$IgNoRe_ErRoR" && exit 8;;                        # EXIT
  esac    # $opt
done    # getopts
shift $OPTIND-1

# set envvars
. $here/$cfgScript -c                         # call with shell sharing
if test $rc -ne 0 
then 
  # error details already reported
  echo "** ERROR $me '. $here/$cfgScript' ended with status $rc"
  test ! "$IgNoRe_ErRoR" && exit 8                             # EXIT
fi    #

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# show input/output details
echo "-- input MVS: $mvsI"
echo "-- input USS: $ussI"
echo "-- output:    $HLQ"

# create SMP/E installable FMID
_relFiles
_smpmcs

# package FMID
# TODO GIMZIP

# update program directory
# TODO PD

echo "-- completed $me 0"
test "$debug" && echo "< $me 0"
exit 0                                                           # EXIT
