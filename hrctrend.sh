#!/bin/sh

# deleted this from Ralph's code source /proj/sot/ska/bin/ska_envs.sh

eval `/home/grant/Ska/sot/ska/bin/flt_envs -shell sh -ska`

cd /home/grant/HRCOps/Data/SentinelData

TODAY=`date +"%Y%m%d"`

echo ${TODAY}
echo

#rm out.mail
#touch out.mail

DATEDIR="/home/grant/HRCOps/Data/SentinelData/${TODAY}"

if [ ! -d ${DATEDIR} ]
then

  echo "Making directory ${DATEDIR}"
  mkdir "/home/grant/HRCOps/Data/SentinelData/${TODAY}"

fi

HRCMSID="2SMTRATM 2SHEV1RT 2TLEV1RT 2VLEV1RT 2FEPRATM"

for MSID in ${HRCMSID}
do

  echo ${MSID}

  python hrctrend.py ${MSID}

  cp ./${MSID}.png "/home/grant/HRCOps/Data/SentinelData/${TODAY}/"

done

echo

# mail -s "${TODAY} Daily Trend Plots" hrcdude@cfa.harvard.edu < out.mail

# uuencode ${MSID}.png ${MSID}.png | mail -s "${TODAY} ${MSID}" rkraft@cfa.harvard.edu

#pwd
#echo "Creating email"
#python imageattach.py -f rkraft@cfa.harvard.edu -t hrcdude@cfa.harvard.edu -s "${TODAY} Daily Trend Plots" *.png
#echo

echo "Successfully Completed"
