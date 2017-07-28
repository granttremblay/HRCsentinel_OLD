#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-037-chk-format_commands.pl
#    Purpose: Check for proper format change commanding
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
	my $rv;
	my $fc;
	my $nr;
	my $ne;
	my $nf;
	my $n;
	my $i;
	my $p;
	my @ERR;
	my @HRCSEL;
	my $L;
	my %Fmt;
	my $dvcdu1;
	my $dvcdu2;



    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	# read the .hrcsel file
	@HRCSEL = ReadFile( "$IP{dd}/$IP{ID}.combined.hrcsel" );


	# loop thru each line of the .hrcsel file
	$rv    = 0;
	$fc    = 0;
	$nr    = 0;
	$nf    = 0;
	$ne    = 0;
	$n     = -1;
	$p     = 0;
	foreach $L (@HRCSEL){

		# remove the cr and split the line on white spaces
		chomp($L);
		@a     = split(" ",$L);


		# check for a S/C format command
		if( $L =~ m/CSELFMT/ ){ 
			$n++;
			$ne = 0;
			$nf = 0;
			$Fmt{$n}{FORMAT_VAL}  = $a[7];
			$Fmt{$n}{FORMAT_VCDU} = $a[2];
			next;
		}

		# check for fifo reset cmd
		if( $L =~ m/2FIFOAOF/ ){ 
			$Fmt{$n}{$nf++}{FIFORESET_VCDU} = $a[2];
			next;
		}


		# check for fifo enable cmd
		if( $L =~ m/2FIFOAON/ ){ 
			$Fmt{$n}{$ne++}{FIFOENABLE_VCDU} = $a[2];
			next;
		}

		# increment the file line counter
		$nr++;
	}



	$rv = 0;
	for($i=0; $i<=$n; $i++){
		$dvcdu1 = $Fmt{$i}{0}{FIFORESET_VCDU}  - $Fmt{$i}{FORMAT_VCDU}; 
		$dvcdu2 = $Fmt{$i}{0}{FIFOENABLE_VCDU} - $Fmt{$i}{FORMAT_VCDU}; 

		if( $dvcdu1 > 3 ){
			$ERR[$rv++] = "fmt_value = $Fmt{$i}{FORMAT_VAL}
fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}
fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)
fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)
";
		}

		if( $dvcdu1 > 8 ){
			$ERR[$rv++] = "fmt_value = $Fmt{$i}{FORMAT_VAL}
fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}
fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)
fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)
";
		}


		if( $IP{DebugLevel} > 0 ){
			print "$i: =======================================\n";
			print "$i: 
fmt_value = $Fmt{$i}{FORMAT_VAL}
fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}
fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)
fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)
			"; 
			print "\n";
		}
	}



	if( $rv == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		for($i=1; $i<=$rv; $i++){
			print " $i: $ERR[$i]\n";
			print "\n";
		}
	}


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
	$$rv{Program}      = "CLP-037-chk-format_commands.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-037-chk-format_commands.pl';
	$$ip{Description} = 'Check for matching S/C and hrc commanding with format changes.';
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




