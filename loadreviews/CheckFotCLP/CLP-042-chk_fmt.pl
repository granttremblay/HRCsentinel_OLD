#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program:CLP-042-chk_fmt.pl
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
	my @b;
	my @c;
	my $delta;
	my $debug;
	my $rv;
	my $i;
	my $j;
	my $ne;
	my $nr;
	my $nx;
	my @HRCSEL;
	my $L;
	my $L2;
	my $Flag;
	my $ftt;
	my $det;
	my $scs;
	my %ERR;
	my %SCS;
	my %HV;
	my %PREAMPA;
	my %FORMATS;
	my %FORMATH;
	my %RADMON;
	my %OBS;
	my $ANGP;
	my $ANGY;
	my $COEFP;
	my $COEFY;
	my $RATEP;
	my $RATEY;
	my $angp;
	my $angy;
	my $coefp;
	my $coefy;
	my $ratep;
	my $ratey;

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


	$ANGP   = "NA";
	$ANGY   = "NA";
	$COEFP  = "NA";
	$COEFY  = "NA";
	$RATEP  = "NA";
	$RATEY  = "NA";

	$angp   = "NA";
	$angy   = "NA";
	$coefp  = "NA";
	$coefy  = "NA";
	$ratep  = "NA";
	$ratey  = "NA";

	### begin master loop of .hrcsel file
	$nr = -1;
	$ne = 0;
	foreach $L (@HRCSEL){

		$nr++;
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



		### first time thru, check for initial FORMAT
		if( ($L =~ m/FMT = /) && ($ftt == 1) ){
			$FORMATS{State}  = $a[2];
			$FORMATH{State}  = $a[2];
			$FORMATS{Line}   = "initial state $L";
			$FORMATH{Line}   = "initial state $L";
			if( $debug == 1 ){
				print "  FORMAT: $FORMATS{Line}\n";
			}
			$ftt = 0;
			next;
		}

		### end of init ###




		### OBS ID 
		if( ($L =~ m/^OBSID =/) ){
			$OBS{ID} = $a[2];
			$OBS{ID} =~ s/://;
			if( $debug == 1 ){print "\n==================================";}
			if( $debug == 1 ){print "\nOBS ID: $OBS{ID}; ";}
			if( $debug == 1 ){print "Current fmt: $FORMATS{State}\n";}
			next;
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



		### S/C FORMATS CHANGE
		if( ($L =~ m/CSELFMT/) ){
			$FORMATS{State} = $a[$#a];
			$FORMATS{Line}  = $L;
			if( $debug == 1 ){print "FORMAT S/C SET $FORMATS{State}  at:$L2\n";}
		}

		### HRC FORMATS CHANGE
		if( ($L =~ m/2OBSVASL/) ){
			$FORMATH{State} = 1;
			$FORMATH{Line}  = $L;
			if( $debug == 1 ){print "FORMAT HRC SET $FORMATH{State}  at:$L2\n";}
		}

		### HRC FORMATS CHANGE
		if( ($L =~ m/2NXILASL/) ){
			$FORMATH{State} = "NIL";
			$FORMATH{Line}  = $L;
			if( $debug == 1 ){print "FORMAT HRC SET $FORMATH{State}  at:$L2\n";}
		}

		### Chk fmt at dither enable
		if( ($L =~ m/DITHER ENABLE/) ){
			if( $debug == 1 && $Flag == 1){print "   START OBS: fmth=$FORMATH{State};  fmts=$FORMATS{State} at:$L2\n";}
			if( ($Flag == 1)  && ($FORMATH{State} == 1)  && ( $FORMATS{State} != 1) ){
				if( $debug == 1 ){print "START HRC OBS: fmt hrc=($FORMATH{State} != 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";}
				$ERR{$ne++} = "START HRC OBS: fmt hrc=($FORMATH{State} != 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";
			}
			
		}



	} ### end of read hrcsel loop





	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne configuration errors:\n";
		for($j=1; $j<=$ne; $j++){
			print "Error [$j]\n";
			print " $ERR{$j}\n";
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
	$$rv{Program}      = "CLP-042-chk_fmt.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-042-chk_fmt.pl';
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






