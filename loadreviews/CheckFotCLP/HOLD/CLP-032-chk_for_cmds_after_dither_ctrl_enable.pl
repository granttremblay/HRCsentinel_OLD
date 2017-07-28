#!/usr/bin/perl -w


# read the .hrcsel file
@FILE = <>;

$vcdu  = 0;
$dvcdu = 0;
$nr    = 0;
$rv    = 0;
# loop thru each line of the .hrcsel file
foreach $L (@FILE){

	# remove the cr and split the line on white spaces
	chomp($L);
	@a    = split(" ",$L);


	# check for 8405B00 -> ACTIVATE SCS 0x5B (91) HRC Dither Control command
	if( $L =~ m/8405B00/ ){ 
		print "\n=====================================\n"; 
		print "$L\n"; 
		$vcdu_start = $a[2]; 
		$nr   = 0;
		$dsec = 0;
		
		next;
	}

	$nr++;
	if( ($#a > 7) && ($nr < 15) && ($a[0] =~ m/\:/) && ($a[1] =~ m/\:/) ){

		$vcdu = $a[2]; 
		$cmd  = $a[3]; 
		
		$dvcdu = $vcdu - $vcdu_start; 
		$dsec  = 4*$dvcdu;
		
		if( ($cmd =~ m/^2/) && ($dsec < 300) ){
			$rv = 1;
			print "  $nr: $dsec : $L\n";
		}	

		
	}


}

print "CLP-032-chk_for_cmds_after_dither_ctrl_enable.pl: ";
if( $rv == 0 ){
	print "[OK]\n";
}else{
	print "[FAIL]\n";
}

exit($rv);
