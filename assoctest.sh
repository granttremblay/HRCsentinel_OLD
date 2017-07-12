#!/bin/bash

# This way, each MSID only needs to be mentioned once
declare -A scaleflags=(
    [2SMTRATM]= 
    [2SHEV1RT]="-l 0 -u prune"
    [2TLEV1RT]="-l 0 -u prune"
    [2VLEV1RT]="-l 0 -u prune"
    [2FEPRATM]="-l 0 -u prune"
)

# Quotes here are redundant, but would allow spaces in the keys
for MSID in "${!scaleflags[@]}"
do

  echo ./hrctrend_scaled.py ${scaleflags[$MSID]} $MSID

done

echo -e "\n\nAlternatively, empty flags can be left undefined in the array\n\n"

# This way you also determine the order of the plots
HRCMSID="2SMTRATM 2SHEV1RT 2TLEV1RT 2VLEV1RT 2FEPRATM"
declare -A altflags=(
    [2SHEV1RT]="-l 0 -u prune"
    [2TLEV1RT]="-l 0 -u prune"
    [2VLEV1RT]="-l 0 -u prune"
    [2FEPRATM]="-l 0 -u prune"
)

for MSID in ${HRCMSID}
do

  echo ./hrctren_scaled.py ${altflags[$MSID]} $MSID

done
