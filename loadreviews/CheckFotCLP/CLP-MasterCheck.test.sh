#!/bin/bash


ROOT=/d0/hrc/occ/mp

H=`pwd`
cd /d0/hrc/occ/mp;
DIRS=$( ls -d 2013* )
cd $H


for DIR in $DIRS
do
	CMD="CLP-MasterCheck.sh $ROOT/$DIR"
	echo "============================================================\n";
	$CMD
	echo; echo
	echo -n "Type <cr> to continue: "
	read x
	clear
done

