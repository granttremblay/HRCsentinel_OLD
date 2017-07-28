#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-039-chk-pmt-on-and-up.pl
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
	my %FTT;
	my $ne;
	my $det;
	my $scs;
	my %ERR;
	my %SCS;
	my %DITHER;
	my %HV;
	my %CTV;
	my %SHLD2PWR;
	my %SHLD2STEP;
	my %PREAMPA;
	my %RADMON;
	my %OBSID;
	my %OBS;
	my %SI;

	my $hrcvcdu;
	my $act_vcdu;
	my $dsec;
	my $dvcdu;
	my $dsteps;
	my $maxvcdu;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/$IP{ID}.combined.hrcsel" );


	# loop thru each line of the .hrcsel file
	$debug          = $IP{DebugLevel};
	$FTT{Shld2Pwr}   = 1;   # shld pwr flag
	$FTT{Shld2Step}  = 1;   # shld hv step flag 
	$FTT{Radmon}    = 1;   # radmon flag
	$FTT{First}     = 1;   # first command flag
	$ne             = 0;   # number of errors
	$scs            = 0;   # scs number
	$maxvcdu         = 200;   # max vcdu counts allowed after radmon ena and hv =on and step=8


	### begin master loop of .hrcsel file
	foreach $L (@HRCSEL){


		# remove the cr and split the line on white spaces
		chomp($L);
		@a    = split(" ",$L);
		if( $#a <= 0 ){ next; }

		# shorten the line by replacing white spaces with a single space
		$L2 = $L;
		$L2 =~ s/ +/ /g;
		$L2 =~ s/	+/ /g;



		### get initial vcdu state
		if( ($L =~ m/^   vcdu = /) ){
			$CTV{Shld2Step}{vcdu} = $a[2];
			$CTV{RadmonEna}{vcdu}    = $a[2];
			$CTV{RadmonDis}{vcdu}    = $a[2];
			$CTV{Shld2Pwr}{vcdu}  = $a[2];
			$CTV{Shld2Pwr}{vcdu}  = $a[2];
			if( $debug == 1 ){ print "Initial  VCDU [vcdu=$a[2]]\n"; }
			next;
		}

		### get initial shld2pwr state
		if( ($L =~ m/^   SHLD2PWR = /) && ($FTT{Shld2Pwr} == 1) ){
			$CTV{Shld2Pwr}{Line}  = $L;
			$CTV{Shld2Pwr}{State} = $a[2];
			if( $debug == 1 ){ print "Initial State [SHLD2PWR=$CTV{Shld2Pwr}{State}]\n"; }
			$FTT{Shld2Pwr} = 0;
			next;
		}

		### get initial SHLD2STEP state
		if( ($L =~ m/^   SHLD2STEP = /) && ($FTT{Shld2Step} == 1) ){
			$CTV{Shld2Step}{Line}      = $L;
			$CTV{Shld2Step}{LastState} = $a[2];
			$CTV{Shld2Step}{State}     = $a[2];
			if( $debug == 1 ){ print "Initial State [SHLD2STEP=$CTV{Shld2Step}{State}]\n"; }
			$FTT{Shld2Step} = 0;
			next;
		}

		### get initial radmon state
		if( ($L =~ m/^   RADMON = /) && ($FTT{Radmon} == 1) ){
			if( $a[2] =~ m/en/ ){
				$CTV{RadmonEna}{State} = $a[2];
				$CTV{RadmonEna}{Line}  = $L;
				if( $debug == 1 ){ print "Initial State [RADMON=$CTV{RadmonEna}{State}]\n"; }
			}
			if( $a[2] =~ m/ds/ ){
				$CTV{RadmonDis}{State} = $a[2];
				$CTV{RadmonDis}{Line}  = $L;
				if( $debug == 1 ){ print "Initial State [RADMON=$CTV{RadmonDis}{State}]\n"; }
			}
			$FTT{Radmon} = 0;
			next;
		}



		### get initial first command state
		if( $L =~ m/FIRST Command in Load/ ) {
			if( $debug == 1 ){ print "First command start: $a[0]\n\n"; }
			$FTT{First} = 0;
			next;
		}
		if( $FTT{First} == 1 ){ next; }







		### Radmon disable
		if( ($L =~ m/Radmon Disable/ ) ){
			if( $debug == 1 ){ print "Radmon Disable:            $L2\n\n"; }
			$CTV{RadmonDis}{vcdu}  = $a[2];
			$CTV{RadmonDis}{Line}  = $L;
			$CTV{RadmonDis}{State} = 'ds';

			# check if shld pwr is off on when radmon is enabled.
			if( ($CTV{Shld2Pwr}{State} =~ "on") ){
				$ERR{$ne++} = "Shield HV is on when radmon is disabled: @ vcdu = $CTV{RadmonDis}{vcdu}\n";
			}

			# check if shld step == 0 when radmon is enabled.
			if( ($CTV{Shld2Step}{State} != 0 ) ){
				$ERR{$ne++} = "Shield HV step is not 0 when radmon is disabled: @ vcdu = $CTV{RadmonDis}{vcdu}\n";
			}
			next;
		}


		### Radmon enable
		if( ($L =~ m/Radmon Enable/ ) ){
			if( $debug == 1 ){ print "Radmon Enable:             $L2\n"; }
			$CTV{RadmonEna}{vcdu}  = $a[2];
			$CTV{RadmonEna}{Line}  = $L;
			$CTV{RadmonEna}{State} = 'en';


			# check if shld pwr is already on when radmon is enabled.
			if( ($CTV{Shld2Pwr}{State} =~ "on") ){
				$ERR{$ne++} = "Shield HV is on when radmon is enabled: @ vcdu = $CTV{RadmonEna}{vcdu}\n";
			}

			# check if shld step != 0 when radmon is enabled.
			if( ($CTV{Shld2Step}{State} != 0 ) ){
				$ERR{$ne++} = "Shield HV step is not 0 when radmon is enabled: @ vcdu = $CTV{RadmonEna}{vcdu}\n";
			}
			next;
		}







		### HRC B shield off
		if( ($L =~ m/2S2HVOF/ ) ){
			if( $debug == 1 ){ print " HRC shield B pwr  off:    $L2\n"; }
			$CTV{Shld2Pwr}{vcdu}  = $a[2];
			$CTV{Shld2Pwr}{Line}  = $L;
			$CTV{Shld2Pwr}{State} = "off";
			next;
		}

		### HRC B shield on
		if( ($L =~ m/2S2HVON/ ) ){
			if( $debug == 1 ){ print " HRC shield B pwr   on:    $L2\n"; }
			$CTV{Shld2Pwr}{vcdu}  = $a[2];
			$CTV{Shld2Pwr}{Line}  = $L;
			$CTV{Shld2Pwr}{State} = "on";
			next;
		}




		### HRC shield step changes
		if( ($L =~ m/2S2STHV/ ) ){
			$CTV{Shld2Step}{LastState} = $CTV{Shld2Step}{State};
			$CTV{Shld2Step}{vcdu}  = $a[2];
			$CTV{Shld2Step}{Line}  = $L;
			$CTV{Shld2Step}{State} = $a[8];
			$CTV{Shld2Step}{State} =~ s/\(//;
			$CTV{Shld2Step}{State} =~ s/\)//;

			if( $debug == 1 ){ print " HRC shield B step $CTV{Shld2Step}{LastState} -> $CTV{Shld2Step}{State}: $L2\n"; }

			# check for more than a 4 step increase
			$dsteps = $CTV{Shld2Step}{State} - $CTV{Shld2Step}{LastState};
			if( $dsteps > 4 ){
				$ERR{$ne++} = "Shield HV step increased (dsteps=$dsteps)  more than 4 steps @ vcdu = $CTV{Shld2Step}{vcdu}\n";
			}
			
			# check if radmon==en &&  step != 8, &&  dvcdu > maxvcdu  
			$dvcdu = $CTV{Shld2Step}{vcdu} - $CTV{RadmonEna}{vcdu};
			$dsec = $dvcdu/2.05;
			$dsec = sprintf("%.2f",$dsec);
			if( ($CTV{Shld2Step}{State} == 8 ) && ($CTV{Shld2Pwr}{State} =~ m/on/)  ){
				if( $debug == 1 ){ print "     shield B step ($CTV{Shld2Step}{State}):     (\@max=8) after ($dsec sec)($dvcdu < $maxvcdu vcdu) after radmon ena\n\n"; 
				}
			}

			if( ($CTV{Shld2Step}{State} < 8 ) && ($CTV{Shld2Pwr}{State} =~ m/on/) && ($dvcdu > $maxvcdu) ){
				$ERR{$ne++} = "Shield HV step is not upto step 8($CTV{Shld2Step}{State}) after ($dvcdu) $maxvcdu vcdu cnts @ vcdu = $CTV{Shld2Step}{vcdu}\n";
			}

			# check is step is > 0 and shld hv is off
			if( ($CTV{Shld2Step}{State} > 0)  &&  ($CTV{Shld2Pwr}{State} =~ m/off/) ){
				$ERR{$ne++} = "Shield HV step is ($CTV{Shld2Step}{State} > 0) && (HV=off) @ vcdu = $CTV{Shld2Step}{vcdu}\n";
			}

			if( $CTV{Shld2Step}{State} > 8 ){
				$ERR{$ne++} = "Shield HV step is ($CTV{Shld2Step}{State} > 8) @ vcdu = $CTV{Shld2Step}{vcdu}\n";
			}
			next;
		}











	} ### end of read hrcsel loop

	### print out error codes
	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne configuration errors:\n";
		for($j=0; $j<$ne; $j++){
			print "Error [$j]\n";
			print " $ERR{$j}\n";
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
	$$rv{Program}      = "CLP-039-chk-pmt-on-and-up.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-039-chk-pmt-on-and-up.pl';
	$$ip{Description} = 'Check for pmt on and up after radiation belts';
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






