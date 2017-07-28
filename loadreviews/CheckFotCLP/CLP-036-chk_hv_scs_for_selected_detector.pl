#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-036-chk_hv_scs_for_selected_detector
#    Purpose: 
#    External files:
#    External programs:
#
#    Copyright:   
#
# === RCS Information ===
# $Rev$
# $Date$
# ========================
#
#
#===========================================================================


use strict;
use FileHandle;
use Getopt::Long;
use File::Basename;
use Cwd;

{ ### start of main program

	### define variables for main program
	my $Version = '$Revision: 1.2 $';
	my %IP;
	my %RV;
	my @a;
	my $debug;
	my $rv;
	my $i;
	my $j;
	my @HRCSEL;
	my $L;
	my $L2;
	my $Flag;
	my $ftt;
	my $ne;
	my $det;
	my $scs;
	my %ERR;
	my %SCS;
	my %HV;
	my %PREAMPA;
	my %RADMON;
	my %OBS;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/$IP{ID}.combined.hrcsel" );


	# loop thru each line of the .hrcsel file
	$debug = $IP{DebugLevel};
	$ftt  = 1;   # first time thru flag
	$Flag = 0;   # active hrc detector flag
	$ne   = 0;   # number of errors
	$scs  = 0;   # scs number
	$SCS{$scs}{State} = 0;
	$SCS{$scs}{Line}  = "NA";
	$RADMON{State}    = -1;
	$OBS{ID}    = -1;
	$OBS{SI}    = "NA" ;

	foreach $scs (qw(87 88 89 90 91 92)){
		$SCS{$scs}{State} = 0;
		$SCS{$scs}{Line}  = "NA";
	}

	### begin master loop of .hrcsel file
	foreach $L (@HRCSEL){

		# $nr++;
		# print "$nr: $nt:RAD=$RAD{$nt}{State}; Shld=$SHLD{$nt}{State}; HVI=$HVI{$nt}{State}; HVS=$HVS{$nt}{State}\n";
		# select(undef, undef, undef, 0.10);

		# remove the cr and split the line on white spaces
		chomp($L);
		@a    = split(" ",$L);
		if( $#a <= 0 ){ next; }

		# shorten the line by replacing white spaces with a single space
		$L2 = $L;
		$L2 =~ s/ +/ /g;
		$L2 =~ s/	+/ /g;


		### first time thru, check for initial preamp states
		if( ($L =~ m/RADMON = /) && ($ftt == 1) ){
			if( $a[2] =~ m/ds/ ){
				$RADMON{State}  = 0;
			}else{
				$RADMON{State}  = 1;
			}
			$RADMON{Line}   = "initial state $L";
			if( $debug == 1 ){
				print "### start of init\n";
				print "  RADMON:$RADMON{Line}: ($RADMON{State})\n";
			}
			next;
		}

		### first time thru, check for initial preamp states
		if( ($L =~ m/PREAMPA = /) && ($ftt == 1) ){
			$PREAMPA{State}  = $a[2];
			$PREAMPA{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  PREAMPA:$PREAMPA{Line}\n"; }
			next;
		}

		### first time thru, check for initial HV states
		if( ($L =~ m/HVI = /) && ($ftt == 1) ){
			$det = "I";
			$HV{$det}{State}  = $a[2];
			$HV{$det}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  HV($det):$HV{$det}{Line}\n"; }
			next;
		}

		### first time thru, check for initial HV states
		if( ($L =~ m/HVS = /) && ($ftt == 1) ){
			$det = "S";
			$HV{$det}{State}  = $a[2];
			$HV{$det}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  HV($det):$HV{$det}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS87 = /) && ($ftt == 1) ){
			$scs = 87;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS88 = /) && ($ftt == 1) ){
			$scs = 88;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line }  = "initial state $L";
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS89 = /) && ($ftt == 1) ){
			$scs = 89;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS90 = /) && ($ftt == 1) ){
			$scs = 90;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS91 = /) && ($ftt == 1) ){
			$scs = 91;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line}   = "initial state $L";
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS92 = /) && ($ftt == 1) ){
			$scs = 92;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line }  = "initial state $L";
	
	if( $HV{I}{State} =~ /off/ ){
		$scs = 92;
		$SCS{$scs}{State} = "term";
	}
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}

		### first time thru, check for initial SCS states
		if( ($L =~ m/SCS93 = /) && ($ftt == 1) ){
			$scs = 93;
			$SCS{$scs}{State}  = $a[2];
			$SCS{$scs}{Line }  = "initial state $L";

	if( $HV{S}{State} =~ /off/ ){
		$scs = 93;
		$SCS{$scs}{State} = "term";
	}
			if( $debug == 1 ){ print "  SCS($scs):$SCS{$scs}{Line}\n"; }
			next;
		}




		if( ($L =~ m/FIRST Command in Load/) && ($ftt == 1) ){
			$ftt = 0;
			if( $debug == 1 ){ print "### end of init\n\n"; }
			next;
		}

		### end of init ###


	#
	# ENABLE SCS 0x59 (89) HRC-I HV Ramp Up
	# DISABLE SCS 0x59 (89) HRC-I HV Ramp Up
	#
	# DISABLE SCS 0x5A (90) HRC-S HV Ramp Up
	# ENABLE SCS 0x5A (90) HRC-S HV Ramp Up
	#
	# ACTIVATE SCS 0x5B (91) HRC Dither Control
	# TERMINATE SCS 0x5B (91) HRC Dither Control
	#
	#
	# ENABLE SCS 0x57 (87) HRC-I HV Ramp Down
	# ACTIVATE SCS 0x57 (87) HRC-I HV Ramp Down
	# DISABLE SCS 0x57 (87) HRC-I HV Ramp Down
	#
	# ENABLE SCS 0x58 (88) HRC-S HV Ramp Down
	# ACTIVATE SCS 0x58 (88) HRC-S HV Ramp Down
	# DISABLE SCS 0x58 (88) HRC-S HV Ramp Down
	#
	# ACTIVATE SCS 0x5C (92) HRC-I HV On
	# ACTIVATE SCS 0x5D (93) HRC-S HV On
	#
	#		if( $b[1] == 87 ){ $SV{HVI} = '1/2'; }
	#		if( $b[1] == 88 ){ $SV{HVS} = '1/2'; }
	#		if( $b[1] == 89 ){ $SV{HVI} = 'up'; }
	#		if( $b[1] == 90 ){ $SV{HVS} = 'up'; }
	#		if( $b[1] == 92 ){ $SV{HVI} = 'on'; }
	#		if( $b[1] == 93 ){ $SV{HVS} = 'on'; }



		### OBS ID 
		if( ($L =~ m/^OBSID =/) ){
			$OBS{ID} = $a[2];
			$OBS{ID} =~ s/://;
			if( $debug == 1 ){print "\n==================================";}
			if( $debug == 1 ){print "\nOBS ID: $OBS{ID}\n";}
		}

		### OBS SI 
		if( ($L =~ m/SI =/) ){
			$OBS{SI} = $a[2];
			if( $debug == 1 ){print "OBS SI: $OBS{SI}\n";}
			if( $OBS{SI} =~ m/HRC/ ){
				$Flag = 1;
			}else{
				$Flag = 0;
			}
		}


		### Radmon Enable 
		if( ($L =~ m/Radmon Enable/) ){
			$RADMON{State} = 1;
			$RADMON{Line}  = $L;
			if( $debug == 1 ){print "RADMON $RADMON{State}  at:$L2\n";}
		}


		### Radmon Disable 
		if( ($L =~ m/Radmon Disable/) ){
			$RADMON{State} = 0;
			$RADMON{Line}  = $L;
			if( $debug == 1 ){print "RADMON $RADMON{State}  at:$L2\n";}
		}





		### HRC-I HV off 
		if( ($L =~ m/2IMHVOF/) ){
			$det = "I";
			$scs = 92;
			$SCS{$scs}{State} = "term";
			$HV{$det}{State}  = "off";
			$HV{$det}{Line}   = $L;
			if( $debug == 1 ){ print "HV $det $HV{$det}{State}  at:$L2\n"; }
		}


		### HRC-S HV off 
		if( ($L =~ m/2SPHVOF/) ){
			$det = "S";
			$scs = 93;
			$SCS{$scs}{State} = "term";
			$HV{$det}{State}  = "off";
			$HV{$det}{Line}   = $L;
			if( $debug == 1 ){ print "HV $det $HV{$det}{State}  at:$L2\n"; }
		}





		### HRC-I HV on - scs92
		if( ($L =~ m/ACTIVATE SCS 0x5C \(92\) HRC-I HV On/) ){
			$scs = 92;
			$det = "I";
			$HV{$det}{State} = "on";
			$SCS{$scs}{State} = "act";
			$SCS{$scs}{Line}  = $L;
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI on at:$L2\n"; }
		}


		### HRC-S HV on - scs93
		if( ($L =~ m/ACTIVATE SCS 0x5D \(93\) HRC-S HV On/) ){
			$scs = 93;
			$det = "S";
			$HV{$det}{State} = "on";
			$SCS{$scs}{State} = "act";
			$SCS{$scs}{Line}  = $L;
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS on at:$L2\n"; }
		}




		### HRC-I HV ramp up - scs89
		if( ($L =~ m/SCS 0x59 \(89\) HRC-I HV Ramp Up/) ){
			$scs = 89;
			if( $a[6] =~ m/ENABLE/ ){
				$SCS{$scs}{State} = "ena";
				$SCS{$scs}{Line}  = $L;
				$det = "I";
				$HV{$det}{State} = "up";
			}
			if( $a[6] =~ m/DISABLE/ ){
				$SCS{$scs}{State} = "dis";
				$SCS{$scs}{Line}  = $L;
			}
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI ramp up at:$L2\n"; }
		}


		### HRC-S HV ramp up  - scs90
		if( ($L =~ m/SCS 0x5A \(90\) HRC-S HV Ramp Up/) ){
			$scs = 90;
			if( $a[6] =~ m/ENABLE/ ){
				$SCS{$scs}{State} = "ena";
				$SCS{$scs}{Line}  = $L;
				$det = "S";
				$HV{$det}{State} = "up";
			}
			if( $a[6] =~ m/DISABLE/ ){
				$SCS{$scs}{State} = "dis";
				$SCS{$scs}{Line}  = $L;
			}
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS ramp up at:$L2\n"; }
		}



		### HRC-I HV ramp down - scs87
		if( ($L =~ m/SCS 0x57 \(87\) HRC-I HV Ramp Down/) ){
			$scs = 87;
			if( $a[6] =~ m/ENABLE/ ){
				$SCS{$scs}{State} = "ena";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/DISABLE/ ){
				$SCS{$scs}{State} = "dis";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/ACTIVATE/ ){
				$SCS{$scs}{State} = "act";
				$SCS{$scs}{Line}  = $L;
				$det = "I";
				$HV{$det}{State} = "1/2";
			}
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI ramp down at:$L2\n"; }
		}


		### HRC-S HV ramp down  - scs88
		if( ($L =~ m/SCS 0x58 \(88\) HRC-S HV Ramp Down/) ){
			$scs = 88;
			if( $a[6] =~ m/ENABLE/ ){
				$SCS{$scs}{State} = "ena";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/DISABLE/ ){
				$SCS{$scs}{State} = "dis";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/ACTIVATE/ ){
				$SCS{$scs}{State} = "act";
				$SCS{$scs}{Line}  = $L;
				$det = "S";
				$HV{$det}{State} = "1/2";
			}
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS ramp down at:$L2\n"; }
		}



		### HRC dither control - scs91
		if( ($L =~ m/SCS 0x5B/ ) ){

			$scs = 91;

			if( $a[6] =~ m/ENABLE/ ){
				$SCS{$scs}{State} = "ena";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/DISABLE/ ){
				$SCS{$scs}{State} = "dis";
				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/ACTIVATE/ ){
				$SCS{$scs}{State} = "act";

				$SCS{$scs}{Line}  = $L;
			}
			if( $a[6] =~ m/TERMINATE/ ){
				$SCS{$scs}{State} = "term";
				$SCS{$scs}{Line}  = $L;
			}

			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n"; }



			if ($SCS{$scs}{State} =~ m/act/) {
				print "==================================================\n";
				print "  OBS: $OBS{ID}/$OBS{SI}\n";

				### check for correct state
				if( $OBS{SI} =~ m/HRC-S/ ){

					# HRC-I states
					$det = "I"; 
					if( $HV{$det}{State} !~ m/off/  ){ $ne++; print "ERROR: HV  $det != off\n"; }
					$scs = 92;
					if( $SCS{$scs}{State}!~ m/term/ ){ $ne++; print "ERROR: SCS $scs HVI on:  != term\n"; }
					$scs = 89;
					if( $SCS{$scs}{State}!~ m/dis/  ){ $ne++; print "ERROR: SCS $scs HVI ramp up:  != dis\n"; }
					$scs = 87;
					if( $SCS{$scs}{State}!~ m/dis/  ){ $ne++; print "ERROR: SCS $scs HVI ramp down:  != dis\n"; 
					}

					# HRC-S states
					$det = "S"; 
					if( $HV{$det}{State}  =~ /off/ ){ $ne++; print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det == off\n"; }

					$scs = 93;
					if( ($SCS{$scs}{State} !~ m/act/) && ($SCS{$scs}{State} !~ m/1\/2/) ){ 
						$ne++;
						print "ERROR: SCS $scs HVS on:  != act|1/2\n"; 
					}

					$scs = 90;
					if( $SCS{$scs}{State} !~ m/ena/ ){ $ne++; print "ERROR: SCS $scs HVS ramp up:  != ena\n"; }

					$scs = 88;
					if( ($SCS{$scs}{State} !~ m/ena/) && ($SCS{$scs}{State}!~ m/act/) ){ 
						$ne++;
						print "ERROR: SCS $scs HVS ramp down:  != ena|act\n"; 
					}
				}




				if( $OBS{SI} =~ m/HRC-I/ ){

					# HRC-S states
					$det = "S"; 
					if( $HV{$det}{State}  !~ m/off/ ){ $ne++; print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det != off\n"; }
					$scs = 93;
					if( $SCS{$scs}{State} =~ m/act/ ){ $ne++; print "ERROR: SCS $scs HVS on:  == act\n"; }
					$scs = 90;
					if( $SCS{$scs}{State} !~ m/dis/ ){ $ne++; print "ERROR: SCS $scs HVS ramp up:  != dis\n"; }
					$scs = 88;
					if( $SCS{$scs}{State} !~ m/dis/ ){ $ne++; print "ERROR: SCS $scs HVS ramp down:  != dis\n"; }


					# HRC-I states
					$det = "I";
					if( $HV{$det}{State}   =~ m/off/ ){ $ne++; print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det == off\n"; }

					$scs = 92;
					if( ($SCS{$scs}{State} !~ m/act/) && ($SCS{$scs}{State} !~ m/1\/2/) ){ 
						$ne++;
						print "ERROR: SCS $scs HVI on:  != act|1/2\n"; 
					}

					$scs = 89;
					if( $SCS{$scs}{State}  !~ m/ena/ ){ $ne++; print "ERROR: SCS $scs HVI ramp up:  != ena\n"; }
					$scs = 87;
					if( ($SCS{$scs}{State}  !~ m/ena/) && ($SCS{$scs}{State}  !~ m/act/) ){ 
						$ne++; print "ERROR: SCS $scs HVI ramp down:  != enai|act\n"; 
					}
				}

				print "\n";


				@a = split(" ", $L2);
				
				$scs = 91;
				print "  SCS $scs HRC Dither control:  $SCS{$scs}{State} @ $a[0]; vcdu=$a[2]\n"; 
				print "\n";


				$det = "S";
				print "  HV $det:  $HV{$det}{State}\n";

				### HRC-S HV on - scs93
				$scs = 93;
				print "  SCS $scs HVS on:  $SCS{$scs}{State}\n"; 


				### HRC-S HV ramp up  - scs90
				$scs = 90;
				print "  SCS $scs HVS ramp up: $SCS{$scs}{State}\n"; 

				### HRC-S HV ramp down  - scs88
				$scs = 88;
				print "  SCS $scs HVS ramp down: $SCS{$scs}{State}\n"; 

				print "\n";


				$det = "I";
				print "  HV $det:  $HV{$det}{State}\n";

				### HRC-I HV on - scs92
				$scs = 92;
				print "  SCS $scs HVI on: $SCS{$scs}{State}\n";

				### HRC-I HV ramp up - scs89
				$scs = 89;
				print "  SCS $scs HVI ramp up: $SCS{$scs}{State}\n"; 

				### HRC-I HV ramp down - scs87
				$scs = 87;
				print "  SCS $scs HVI ramp down: $SCS{$scs}{State}\n"; 

				print "\n";

			}

		}


		#if( (${State} == 0) ){
#
#			$scs = 89;
#			if($SCS{$scs}{State} =~ m/ena/){
#				$ne++;
#				$ERR{$ne} = "";
#			}
#		}




	} ### end of read hrcsel loop

	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne configuration errors:\n";
		#for($j=1; $j<=$ne; $j++){
		#	print "Error [$j]\n";
		#	print " $ERR{$j}\n";
		#	print "\n";
		#}
	}

	$rv = $ne;
	exit($rv);

} ### end of main program





#=============================================================================
sub ReadFile
{

	my ($RDBFILE) = @_;
	my @a;

	open( FD, $RDBFILE ) || die "Can't open file: $RDBFILE\n";
	  @a = <FD>;
	close(FD);
 
	return(@a);
}


#=============================================================================
sub PrnUsage
{
	my ($argv, $ip) = @_;
	my %IP;
	my @ARGV;

	%IP = %$ip;
	@ARGV = @$argv;

	print "---------------------------------------------------------\n";
	print "$IP{Prog} ($IP{Version}) $IP{Description}\n";
	print "---------------------------------------------------------\n";
	print "usage: $IP{Prog} [Options] Products_Directory\n";
	print "Options: [defaults in brackets after descriptions]\n";
  	print " -ps steps   Set the process steps to be executed; \n";
	print "             examples: (note no spaces allowed in argument field)\n";
	print "              -ps 1,4-6,8,9     process steps 1,4,5,6,8,9 \n";
	print "              -ps 4-            process steps 4,5,6,..,$IP{PSMax}\n";
	print "              -ps 3,6           process steps 3,6 \n";
	print " -d|debug    Set the program debug level [$IP{DebugLevel}] \n";
	print " -v|verbose  Set the program verbose level [$IP{VerboseLevel}] \n";
	print " -version    Report the program version [$IP{Version}] \n";
	print " -h|help     Print this message\n";


	return(0);

}



#=============================================================================
sub ErrorExit
{
	my ($rv) = @_;
	my %RV;

	%RV = %$rv;

	print "Program Error:\n";
	print " $RV{Program}\n";
	print " Program: $$rv{Program}\n";
	print " Subroutine: $$rv{Subroutine}\n";
	print " Section: $$rv{Section}\n";
	print " Error Message: $$rv{ErrorMessage}\n";

	exit( $$rv{ReturnValue} );
}

#===================================================================
sub GetIP {

    my ($argv, $ip, $rv) = @_;

    my %IP;
    my @ARGV;
    my %RV;

    ### check for valid Input Parameters (IP) before starting
    #   Input: hash containing all runtime Input Parameters (%IP)
    #   Returns: 0 => valid input;  1 => invalid input parameters

    ### assign the passed pointers to vars
    %IP    = %$ip;
    @ARGV  = @$argv;
    %RV    = %$rv;


	### set the default runtime values
	# Return Value Structure
	$$rv{Program}      = "CLP-036-chk_hv_scs_for_selected_detector.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-036-chk_hv_scs_for_selected_detector.pl';
	$$ip{Description} = 'Check hv scs for selected detector.';
	$$ip{CmdLine}     = "@ARGV";
	$$ip{Version}     = '$Rev$';
	$$ip{PrintVersion}= 0;
	$$ip{DebugLevel}  = 0;
	$$ip{VerboseLevel}= 0;
	$$ip{Help}        = 0;

	# program specific input parameters
	$$ip{dd}           = '.';
	$$ip{ID}           = 'NA';



	### get the command line options
	if( GetOptions(
			"version"     => \$$ip{PrintVersion},
			"v|verbose=i" => \$$ip{VerboseLevel},
			"d|debug=i"   => \$$ip{DebugLevel},
			"h|help"      => \$$ip{Help},
		) ){

		# good commandline processing 
		$$rv{ReturnValue} = 0;
		
	}else{
		# bad commandline processing 
		$$rv{Section}      = "GetOptions";
		$$rv{ErrorMessage} = "Error in parsing commandline";
		$$rv{ReturnValue} = 1;
	}

	if( defined($ARGV[$#ARGV]) ){
		$$ip{dd} = $ARGV[$#ARGV];
	}

	### go home
	return($$rv{ReturnValue});

}

#===================================================================
sub ValidateIP {


    my ($argv, $ip, $rv) = @_;

    my %IP;
    my @ARGV;
    my %RV;

	my @a;
	my $file;
	my $c;
	my $cwd;
	my $cmd;

    ### check for valid Input Parameters (IP) before starting
    #   Input: hash containing all runtime Input Parameters (%IP)
    #   Returns: 0 => valid input;  1 => invalid input parameters

    ### assign the passed pointers to vars
    %IP    = %$ip;
    @ARGV  = @$argv;
    %RV    = %$rv;


	# Return Value Structure
	$$rv{Subroutine}   = "ValidateIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;



	### check for a print version request
	if( $$ip{PrintVersion} == 1 ){
		print "$$ip{Prog}\t$$ip{Version}\n";
		$$rv{ReturnValue}  = 0;
		exit($$rv{ReturnValue});
	}


	### check for a print help request
	if( $$ip{Help} == 1 ){
		$rv = PrnUsage($argv, $ip);
		$$rv{ReturnValue}  = 0;
		exit($$rv{ReturnValue});
	}

	### check for valid data dir 
	$$ip{basename}   = basename($$ip{dd});
	$$ip{dirname}    = dirname($$ip{dd});
	
	### check for valid data directory and get product ID
	if( ! -d $$ip{dd} ){
		$$rv{ErrorMessage} = "Data Directory does not exit [$$ip{dd}]\n";
		$$rv{Section}      = "Check for valid data directory.";
		$$rv{ReturnValue}  = 1;
		return($$rv{ReturnValue});
	}else{
		$cwd = getcwd();
		chdir( $$ip{dd} );
		$cmd  = "ls *.hrcsel > /dev/null";
		$c = system($cmd);
		if( $c == 0 ){
			$cmd  = "ls *.hrcsel";
			$file = `$cmd`;
			chomp($file);
			@a    = split('\.',$file);
			$$ip{ID}  = $a[0];
			chdir( $cwd );
		}else{
			$$rv{ErrorMessage} = "hrcsel file does not exit in dir [$$ip{dd}]\n";
			$$rv{Section}      = "Check for valid data directory files (*hrcsel).";
			$$rv{ReturnValue}  = 1;
			return($$rv{ReturnValue});
		}
	}

	### go home
	return($RV{ReturnValue});

}






