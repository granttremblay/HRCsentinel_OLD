#!/bin/bash

# this script tests the HRC command load checks
# usage: test-script ID
#

ID=$1
if SCRIPT=$( ls CLP-$ID-* )
then
	echo "Testing: $SCRIPT"
else	
	echo "Test script not found: $SCRIPT"
	echo "Usage: test-script.sh  040"
	echo
	exit
fi


# MP products root directory
ROOT=/d0/hrc/occ/mp

# get a list for app product release for 2011
H=`pwd`
cd /d0/hrc/occ/mp;
DIRS=$( ls -d 2012* )
cd $H


### loop thru each of the released product directories and execute the test script
for DIR in $DIRS
do
	CMD="$SCRIPT  $ROOT/$DIR"
	echo "============================================================\n";
	echo "Testing Products: $DIR"
	echo "Testing Command:  $CMD"
	$CMD
	echo; echo
done

