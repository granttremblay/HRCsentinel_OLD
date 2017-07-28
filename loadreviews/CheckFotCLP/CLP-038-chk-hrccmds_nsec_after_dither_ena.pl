#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-038-chk-hrccmds_nsec_after_dither_ena.pl
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
	my $sftt;
	my $dftt;
	my $vftt;
	my $ne;
	my $det;
	my $scs;
	my %ERR;
	my %SCS;
	my %DITHER;
	my %HV;
	my %PREAMPA;
	my %RADMON;
	my %OBS;
	my @CSDT;
	my $csdtn;

	my $hrcvcdu;
	my $act_vcdu;
	my $dsec;
	my $dvcdu;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/$IP{ID}.combined.hrcsel" );


	# loop thru each line of the .hrcsel file
	$debug = $IP{DebugLevel};
	$dftt  = 1;   # dither first time thru flag
	$sftt  = 1;   # scs91 first time thru flag
	$vftt  = 1;   # vcdu first time thru flag
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


		# remove the cr and split the line on white spaces
		chomp($L);
		@a    = split(" ",$L);
		if( $#a <= 0 ){ next; }

		# shorten the line by replacing white spaces with a single space
		$L2 = $L;
		$L2 =~ s/ +/ /g;
		$L2 =~ s/	+/ /g;

		@CSDT = split(':', $a[0]);
#print "\@CSDT  = @CSDT\n";
#print "\@CSDTn = $#CSDT\n";
#print "\$a[0]  = $a[0]\n";
#print " YYYY   = $CSDT[0]\n";

		### get initial vcdu state
		if( ($L =~ m/^   vcdu = /) && ($vftt == 1) ){
			$vftt = 0;
			$DITHER{vcdu}     = $a[2];
			$SCS{$scs}{vcdu}  = $a[2];
			if( $debug == 1 ){ print "Initial State [vcdu=$a[2]]\n"; }
			next;
		}


		### get initial dither state
		if( ($L =~ m/^   DITHER = /) && ($dftt == 1) ){
			$DITHER{State} = $a[2];
			$DITHER{Line}  = $L;
			if( $debug == 1 ){ print "Initial State [Dither=$DITHER{State}]\n"; }
			$dftt = 0;
			next;
		}

		### get initial scs91 state
		if( ($L =~ m/^   SCS91 = /) && ($sftt == 1) ){
			$SCS{$scs}{Line}  = $L;
			$SCS{$scs}{State} = $a[2];
			if( $debug == 1 ){ print "Initial State [scs91=$SCS{$scs}{State}]\n"; }
			$sftt = 0;
			next;
		}




		### HRC dither control - scs91
		if( ($L =~ m/SCS 0x5B/ ) ){

			$scs = 91;

			if( $a[6] =~ m/ACTIVATE/ ){
				$SCS{$scs}{State} = "act";
				$SCS{$scs}{Line}  = $L;
				$SCS{$scs}{vcdu}  = $a[2];
			}
			if( $a[6] =~ m/TERMINATE/ ){
				$SCS{$scs}{State} = "term";
				$SCS{$scs}{Line}  = $L;
				$SCS{$scs}{vcdu}  = $a[2];
			}

			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n"; }

			next;
		}


		### HRC dither enable
		if( ($L =~ m/AOENDITH/ ) ){

			if( $debug == 1 ){ print "HRC Dither enable at:$L2\n"; }
			$DITHER{vcdu}  = $a[2];
			$DITHER{Line}  = $L;
			$DITHER{State} = "en";
			next;
		}


		$scs = 91;
		####if( ($SCS{$scs}{State} =~ m/act/) && ($DITHER{State} =~ m/en/) && ($#a > 4) && ($a[3] =~ m/^2/) ){
		if( ($SCS{$scs}{State} =~ m/act/) && ($DITHER{State} =~ m/en/) && ($#CSDT == 4) && ($a[3] =~ m/^2/) ){

			if( $DITHER{vcdu} >= $SCS{$scs}{vcdu} ){
				$act_vcdu = $DITHER{vcdu};
			}else{
				$act_vcdu = $SCS{$scs}{vcdu};
			}
			$hrcvcdu = $a[2];
			$dvcdu   = $hrcvcdu - $act_vcdu;
			$dsec    = $dvcdu / 4.;
			
			if( $debug == 1 ){ print "\n  hrccmd: [91=$SCS{$scs}{State}] [D=$DITHER{State}]:($dsec): $L2\n\n"; }
			##### takes 205 seconds to get to HV
			if( $dsec < 250 ){ 
				printf("    %5.1f: %s\n",$dsec,$L2); $ne++;
				#print "ERRORS: hrccmd: [91=$SCS{$scs}{State}] [D=$DITHER{State}]:($dsec): $L2\n"; 
				#print "ERRORS: L2=$L2\n"; 
				#print "ERRORS: hrcvcdu=$hrcvcdu\n"; 
				#print "ERRORS: act_vcdu=$act_vcdu\n"; 
				#print "ERRORS: act_vcdu=$act_vcdu\n"; 
				#print "ERRORS: YYYY=$CSDT[0]\n"; 
				#print "ERRORS: CSDTn=$#CSDT\n"; 
			}
		}


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
	$$rv{Program}      = "CLP-038-chk-hrccmds_nsec_after_dither_ena.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-038-chk-hrccmds_nsec_after_dither_ena.pl';
	$$ip{Description} = 'Check for hrc cmds after dither enable.';
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






