#!/bin/bash


DD=$@
if [ ! -d $DD ]
then
	echo "usage: 00-Check DD"
	exit 1
fi


CHECKPROGS="
CLP-030-chk_for_cmd_timing_lt_1sec.pl
CLP-031-chk_for_cmds_between_radmon-disable.pl
CLP-033-chk_for_HV_down_in_radzone.pl
CLP-034-chk_for_bad_cmd_hex.pl
CLP-036-chk_hv_scs_for_selected_detector.pl
CLP-037-chk-format_commands.pl
CLP-038-chk-hrccmds_nsec_after_dither_ena.pl
CLP-039-chk-pmt-on-and-up.pl
CLP-040-chk_dither_par.pl
CLP-041-chk_mechanism_cmds.pl
CLP-042-chk_fmt.pl
CLP-043-chk_discrete_hv_cmds_cmds.pl
CLP-044-chk_hrc_cmds_in_vehicle_loads.pl
CLP-045-chk_hrc_scs_in_vehicle_loads.pl
"

echo "=== CLP-MasterCheck.sh $DD ==="
echo "Command Line: CLP-MasterCheck.sh $DD"
date
csdt
echo "=== CLP-MasterCheck.sh $DD ==="
echo

NE=0;
for i in $CHECKPROGS
do
	CMD="$i $DD"
	echo "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
	echo "$CMD"
	$CMD
	rv=$?
	NE=$(( $NE + $rv ))
	echo
done
echo "$NE errors found in load review"
