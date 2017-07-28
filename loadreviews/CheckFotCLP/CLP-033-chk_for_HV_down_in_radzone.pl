#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-033-chk_for_HV_down_in_radzone.pl
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
	my $debug;
	my $i;
	my $j;
	my $L;
	my $ftt;
	my $os;
	my $ne;
	my $nt;
	my $nr;
	my $rv;
	my @a;
	my @HRCSEL;
	my %ERR;
	my %IP;
	my %RAD;
	my %RV;
	my %SHLD; 
	my %HVI;
	my %HVS;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/$IP{ID}.combined.hrcsel" );


	# loop thru each line of the .hrcsel file
	$debug = $IP{DebugLevel};
	$nr = 0;
	$os = 0;
	$ftt = 1;   # first time thru flag
	$ne  = 0;   # number of errors
	$nt  = 0;  # number of transitions
	$RAD{$nt}{State} = 0;
	$RAD{$nt}{Line}  = "NA";

	$SHLD{$nt}{State}= 0;
	$SHLD{$nt}{Line} = "NA";

	$HVI{$nt}{State} = 0;
	$HVI{$nt}{Line}  = "NA";

	$HVS{$nt}{State} = 0;
	$HVS{$nt}{Line}  = "NA";

	if($debug == 1){ print "### Starting Readline:\n";}
	foreach $L (@HRCSEL){

		# $nr++;
		# print "$nr: $nt:RAD=$RAD{$nt}{State}; Shld=$SHLD{$nt}{State}; HVI=$HVI{$nt}{State}; HVS=$HVS{$nt}{State}\n";
		# select(undef, undef, undef, 0.10);

		# remove the cr and split the line on white spaces
		chomp($L);
		@a    = split(" ",$L);
		if( $#a <= 0 ){ next; }


		### first time thru, check for initial HV states
		if( ($L =~ m/HVI = /) && ($ftt == 1) ){
			if( ($a[$#a] =~ m/off/) ||  ($a[$#a] =~ m/2/) ){
				$HVI{$nt}{State} = 0;
				$HVI{$nt}{Line}  = " Initial HVI Load Starting With $HVI{$nt}{State}  $L";
			}
			if( ($a[$#a] =~ m/up/) ){
				$HVI{$nt}{State} = 1;
				$HVI{$nt}{Line}  = " Initial HVI Load Starting With $HVI{$nt}{State}  $L";
			}
			 if($debug == 1){ print "  HVI:$HVI{$nt}{Line}\n";}
			next;
		}

		### first time thru, check for initial HV states
		if( ($L =~ m/HVS = /) && ($ftt == 1) ){
			if( ($a[$#a] =~ m/off/) ||  ($a[$#a] =~ m/2/) ){
				$HVS{$nt}{State} = 0;
				$HVS{$nt}{Line}  = " Initial HVS Load Starting With $HVS{$nt}{State}  $L";
			
			}
			if( ($a[$#a] =~ m/up/) ){
				$HVS{$nt}{State} = 1;
				$HVS{$nt}{Line}  = " Initial HVS Load Starting With $HVS{$nt}{State}  $L";
			}
			 if($debug == 1){ print "  HVS:$HVS{$nt}{Line}\n"; }
			next;
		}

		### first time thru, check for initial shield power states
		if( ($L =~ m/SHLD2PWR = /) && ($ftt == 1) ){
			if( ($a[$#a] =~ m/off/) ){
				$SHLD{$nt}{State} = 0;
				$SHLD{$nt}{Line}  = " Initial SHLDHV Load Starting With $SHLD{$nt}{State}  $L";
			
			}else{
				$SHLD{$nt}{State} = 1;
				$SHLD{$nt}{Line}  = " Initial SHLDHV Load Starting With $SHLD{$nt}{State}  $L";
			}
			 if($debug == 1){ print "  SHLD:$SHLD{$nt}{Line}\n"; }
			next;
		}



		### first time thru, check for initial radmon states - if radmon is ds, we are in rad zone = 1
		if( ($L =~ m/RADMON = /) && ($ftt == 1) ){
			if( $a[$#a] =~ m/ds/ ){
				$RAD{$nt}{State} = 1;
				$RAD{$nt}{Line}  = " Initial Load Starting With $RAD{$nt}{State}  $L";
			
			}else{
				$RAD{$nt}{State} = 0;
				$RAD{$nt}{Line}  = " Initial Load Starting With $RAD{$nt}{State}  $L";
			}
			 if($debug == 1){ print "  RAD:$RAD{$nt}{Line}\n"; }
			next;
		}

		if( ($L =~ m/FIRST Command in Load/) && ($ftt == 1) ){
			$ftt = 0;
			 if($debug == 1){ print "### end of init section\n\n"; }
			next;
		}

		if( ($ftt == 1) ){ next; }

		### end of init


		#
		# set RADIATION ENTRY 
		if( $L =~ m/ELECTRON 1 RADIATION ENTRY 0/ ){ 
			$os = 0;
			$nt++;
			$SHLD{$nt}{State} = $SHLD{$nt-1}{State};
			$HVI{$nt}{State}  = $HVI{$nt-1}{State};
			$HVS{$nt}{State}  = $HVS{$nt-1}{State};

			$RAD{$nt}{State} = 1;
			$RAD{$nt}{Line}  = $L;
			if($debug == 1){ print "\nRAD Entry at:[$nt]  $a[0]\n"; }
			next;
		}

		# set RADIATION EXIT 
		if( $L =~ m/ELECTRON 1 RADIATION EXIT/ ){ 
			$os = 0;
			$nt++;
			$SHLD{$nt}{State} = $SHLD{$nt-1}{State};
			$HVI{$nt}{State}  = $HVI{$nt-1}{State};
			$HVS{$nt}{State}  = $HVS{$nt-1}{State};

			$RAD{$nt}{State} = 0;
			$RAD{$nt}{Line}  = $L;
			if($debug == 1){ print "RAD Exit  at:[$nt]  $a[0]\n"; }
			next;
		}


		# SHLD 1 or 2 on ?
		if( ($L =~ m/2S1HVON/) || ($L =~ m/2S2HVON/) ){ 
			$SHLD{$nt}{State} = 1;
			$SHLD{$nt}{Line}  = $a[0];
			if($debug == 1){ print "SHLD on   at:[$nt]  $a[0]\n"; }
			next;
		}


		# SHLD 1 or 2 HV  off ?
		if( ($L =~ m/2S1HVOF/) || ($L =~ m/2S2HVOF/) ){ 
			$SHLD{$nt}{State} = 0;
			$SHLD{$nt}{Line}  = $a[0];
			if($debug == 1){ print "SHLD off   at:[$nt]  $a[0]\n"; }
			next;
		}

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


		# HRC-I ramp up enabled ?ENABLE SCS 0x59 (89) HRC-I HV Ramp Up
		if( ($L =~ m/ENABLE SCS 0x59/)  ){ 
			$HVI{$nt}{State} = 1;
			$HVI{$nt}{Line}  = $a[0];
			if($debug == 1){ print "HVI EN ramp up at:[$nt]  $a[0]\n"; }
		}

		# HRC-I ramp up disabled ?DISABLE SCS 0x59 (89) HRC-I HV Ramp Up
		if( ($L =~ m/DISABLE SCS 0x59/) ){ 
			$HVI{$nt}{State} = 0;
			$HVI{$nt}{Line}  = $a[0];
			if($debug == 1){ print "HVI DS ramp up at:[$nt]  $a[0]\n"; }
		}




		# HRC-S ramp up enabled ?ENABLE SCS 0x5A (90) HRC-S HV Ramp Up
		if( ($L =~ m/ENABLE SCS 0x5A/) ){ 
			$HVS{$nt}{State} = 1;
			$HVS{$nt}{Line}  = $a[0];
			if($debug == 1){ print "HVS EN ramp up at:[$nt]  $a[0]\n"; }
		}

		# HRC-S ramp up disabled ?DISABLE SCS 0x5A (90) HRC-S HV Ramp Up
		if( ($L =~ m/DISABLE SCS 0x5A/) ){ 
			$HVS{$nt}{State} = 0;
			$HVS{$nt}{Line}  = $a[0];
			if($debug == 1){ print "HVS DS ramp up at:[$nt]  $a[0]\n"; }
		}



		# if we are in the rad zone AND if any HV are up or enabled, flag as error.
		if( ( $RAD{$nt}{State} == 1 ) ){

			if( ( $SHLD{$nt}{State} == 1 ) || ( $HVI{$nt}{State} == 1 ) || ( $HVS{$nt}{State} == 1 ) ){

				if( $os == 0 ){
if($debug == 1){ print "   $L\n"; }
					# save the number error, line, and radmon transition number
					$ne++;
					$ERR{$ne}{LINE}  = "Shld=$SHLD{$nt}{State}; HVI=$HVI{$nt}{State}; ; HVS=$HVS{$nt}{State};";
					$ERR{$ne}{NT}    = $nt;
					if($debug == 1){ print "   Err# $ne; found error [@ transition $nt] 	$ERR{$ne}{LINE}\n\n"; }
					$os = 1;
				}
			}
		}





	}

	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne HRC HV active after radiation entry:\n";
		for($j=1; $j<=$ne; $j++){
			print "Error [$j]\n";
			$nt = 	$ERR{$j}{NT};
			print " $RAD{$nt}{Line}\n";
			print "    $ERR{$j}{LINE}\n";
			$nt++;
			print " $RAD{$nt}{Line}\n";
			print "\n";
		}
	
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
	$$rv{Program}      = "CLP-033-chk_for_HV_down_in_radzone.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-033-chk_for_HV_down_in_radzone.pl';
	$$ip{Description} = 'Check for hrc cmds between radmon.';
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






