#!/bin/sh

source /proj/sot/ska/bin/ska_envs.sh

cd /data/barney/kraft/hrc/

TODAY=`date +"%Y%m%d"`

echo ${TODAY}
echo

rm out.mail
touch out.mail

DATEDIR="/data/barney/kraft/hrctrend/${TODAY}"

if [ ! -d ${DATEDIR} ]
then

  echo "Making directory ${DATEDIR}"
  mkdir "/data/barney/kraft/hrctrend/${TODAY}"

fi

HRCMSID="2SMTRATM 2SHEV1RT 2TLEV1RT 2VLEV1RT 2FEPRATM"

for MSID in ${HRCMSID}
do

  echo ${MSID}

  python hrctrend.py ${MSID}

  cp ./${MSID}.png "/data/barney/kraft/hrctrend/${TODAY}/"

  uuencode ${MSID}.png ${MSID}.png >> out.mail

done

echo

# mail -s "${TODAY} Daily Trend Plots" hrcdude@cfa.harvard.edu < out.mail

# uuencode ${MSID}.png ${MSID}.png | mail -s "${TODAY} ${MSID}" rkraft@cfa.harvard.edu

pwd
echo "Creating email"
python imageattach.py -f rkraft@cfa.harvard.edu -t hrcdude@cfa.harvard.edu -s "${TODAY} Daily Trend Plots" *.png
echo

echo "Successfully Completed"
