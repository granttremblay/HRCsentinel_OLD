#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-045-chk_hrc_scs_in_vehicle_loads.pl
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
	my %SCS;
	my %HV;
	my %PREAMPA;
	my %RADMON;
	my %OBS;
	my @ERR;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/vehicle/$IP{ID}.vehicle.hrcsel" );


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



		### HRC-I HV on - scs92
		if( ($L =~ m/ACTIVATE SCS 0x5C \(92\) HRC-I HV On/) ){
			$scs = 92;
			$ne++;
			$ERR[$ne] = "SCS $scs HVI on at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI on at:$L2\n"; }
		}


		### HRC-S HV on - scs93
		if( ($L =~ m/ACTIVATE SCS 0x5D \(93\) HRC-S HV On/) ){
			$scs = 93;
			$ne++;
			$ERR[$ne] = "SCS $scs  HVS on at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS on at:$L2\n"; }
		}


		### HRC-I HV ramp up - scs89
		if( ($L =~ m/SCS 0x59 \(89\) HRC-I HV Ramp Up/) ){
			$scs = 89;
			$ne++;
			$ERR[$ne] = "SCS $scs HVI ramp up at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI ramp up at:$L2\n"; }
		}


		### HRC-S HV ramp up  - scs90
		if( ($L =~ m/SCS 0x5A \(90\) HRC-S HV Ramp Up/) ){
			$scs = 90;
			$ne++;
			$ERR[$ne] = "SCS $scs HVS ramp up at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS ramp up at:$L2\n"; }
		}


		### HRC-I HV ramp down - scs87
		if( ($L =~ m/SCS 0x57 \(87\) HRC-I HV Ramp Down/) ){
			$scs = 87;
			$ne++;
			$ERR[$ne] = "SCS $scs $SCS{$scs}{State} HVI ramp down at:$L2\n";
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVI ramp down at:$L2\n"; }
		}


		### HRC-S HV ramp down  - scs88
		if( ($L =~ m/SCS 0x58 \(88\) HRC-S HV Ramp Down/) ){
			$scs = 88;
			$ne++;
			$ERR[$ne] = "SCS $scs $SCS{$scs}{State} HVS ramp down at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HVS ramp down at:$L2\n"; }
		}



		### HRC dither control - scs91
		if( ($L =~ m/SCS 0x5B/ ) ){
			$scs = 91;
			$ne++;
			$ERR[$ne] = "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n"; 
			if( $debug == 1 ){ print "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n"; }
		}



	} ### end of read hrcsel loop

	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne hrc specific scs's called in vehicle loads:\n";
		for($j=1; $j<=$ne; $j++){
			print "Error [$j]\n";
			print " $ERR[$j]\n";
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
	$$rv{Program}      = "CLP-045-chk_hrc_scs_in_vehicle_loads.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-045-chk_hrc_scs_in_vehicle_loads.pl';
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






