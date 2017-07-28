#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: 
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


{ ### start of main program

	### define variables for main program
	my $Version = '$Revision: 1.2 $';
	my %IP;
	my $md5sum;
	my $P;
	my @Files;
	my @a;
	my $step;
	my $rv;
	my $csdt;
	my $N;
	my %Time;
	my %RV;



	### get the program start time
	$Time{Start} = time();
	

    ### Get/Set the runtime Input Parameters (IP)
    if( $rv = GetIP(\@ARGV, \%IP, \%RV) != 0 ){ ErrorExit(\%RV); }

    ### Validate Input Parameters (IP)
    if( $rv = ValidateIP(\@ARGV, \%IP, \%RV) != 0   ){ ErrorExit(\%RV); }


	### Print program header
	$rv = PrnHeader(\@ARGV, \%IP, \%RV);


	### get the process steps
	$IP{PSSteps} = GetProcessSteps(%IP); 


	### Print md5 checksums of the input data files
	push( @Files,  $IP{Prog} );
	$N = $#ARGV;
	while($N > -1){
		push( @Files,  $ARGV[$N] );
		$N--;
	}
	if( $rv = PrnMD5( @Files ) > 0 ){ exit($rv); }



	### loop thru each process step
	@a = split(" ",$IP{PSSteps});
	foreach $step (@a){

		# get the current time 
		$Time{Current} = time();
		$Time{Runtime} = $Time{Current} - $Time{Start};
		$csdt = `date +'%Y:%j:%H:%M:%S'`;
		chomp($csdt);

		### process step 1
		if( $step == 1 ){
			print "#===================================================\n";
			print "# Process Step: $step\n";
			print "# Time  $csdt  $Time{Runtime}\n";
			print "# [PASS] - Step $step - \n";
			print "#\n";
			$rv = 0;
			sleep(1);
		}

		### process step 2
		if( $step == 2 ){
			print "#===================================================\n";
			print "# Process Step: $step\n";
			print "# Time  $csdt  $Time{Runtime}\n";
			print "# [PASS] - Step $step - \n";
			print "#\n";
			$rv = 0;
			sleep(1);
		}


		### process step 3
		if( $step == 3 ){
			print "#===================================================\n";
			print "# Process Step: $step\n";
			print "# Time  $csdt  $Time{Runtime}\n";
			print "# [PASS] - Step $step - \n";
			print "#\n";
			$rv = 0;
			sleep(1);
		}

		### process step 4
		if( $step == 4 ){
			print "#===================================================\n";
			print "# Process Step: $step\n";
			print "# Time  $csdt  $Time{Runtime}\n";
			print "# [PASS] - Step $step - \n";
			print "#\n";
			$rv = 0;
			sleep(1);
		}
	}


	$Time{Current} = time();
	$Time{Runtime} = $Time{Current} - $Time{Start};
	$csdt = `date +'%Y:%j:%H:%M:%S'`;
	chomp($csdt);
	print "# STOP $IP{Prog} @ $csdt ; RunTime(sec) $Time{Runtime} =+=+=+=+=+=+=+=+\n";
	print "# Program Exits with: $rv\n";
	print "#==================================================================\n";

	exit($rv);

} ### end of main program




#=============================================================================
sub GetProcessSteps
{

	my (%IP) = @_;

	### define local vars
	my @a;
	my @b;
	my @c;
	my $i;
	my $j;
	my $maxps;
	my $rv;


	$maxps = $IP{PSMax};

	# cmd line fmt:  1,2,4-5,6-,-8

	# split the command line arg on ','s
	@a = split(",",$IP{PS});

	# loop thru each comma group: 
	for($i=0; $i<=$#a; $i++){


		# check if the comma group has a dash, if not push it in the list
		if( $a[$i] =~ /\-/ ){

			# split the comma group on a -
			@b = split("-",$a[$i]);

			if( $a[$i] =~ /^\-/ ){
				# dash at start
				for($j=1; $j<=$b[1]; $j++){ push(@c,$j); }

			}elsif( $a[$i] =~ /\-$/ ){
				# dash at end
				for($j=1; $j<=$maxps; $j++){ push(@c,$j); }

			}else{
				# dash at mid
				for($j=$b[0]; $j<=$b[1]; $j++){ push(@c,$j); }
			}

		}else{
			push(@c,$a[$i]);
		}
	}
		

	return ("@c");
}



#=============================================================================
sub PrnMD5
{
	my ( @Files ) = @_;
	my $csdt;
	my $file;
	my $md5sum;
	my $rv;


	### set the default values
	$csdt  = '';
	$file  = '';
	$rv    = 0;

	### calculate the md5 checksum of the input data files
	$csdt = `date +'%Y:%j:%H:%M:%S'`;
	chomp( $csdt );

	print "#===================================================\n";
	print "# Subroutine PrnMD5 - Calculate md5sum checksum of the input files:\n";
	print "# Time:$csdt\n";

	### calculate the md5 checksum of the cmd delog file
	foreach $file (@Files){
		if( -e $file ){
			$md5sum = `md5sum $file`;
			chomp($md5sum);
			print "# [PASS] - $md5sum\n";
		}else{
			print "# [FAIL] - Input file does not exist: $file\n";
			$rv = 1;
		}
	}
	print "#\n";

	return($rv);

}



#=============================================================================
sub ReadFile
{

	my ($RDBFILE) = @_;
	my @a;

	open( FD, $RDBFILE ) || die "Can't open OR file:$RDBFILE\n";
	  @a = <FD>;
	close(FD);
 
	return(@a);
}

#=============================================================================
sub PrnHeader
{

	my ($argv, $ip, $rv) = @_;

	my %IP;
	my @ARGV;
	my $md5sum;
	my $P;
	my @a;
	my $PRCS;
	my $csdt;
	my $host;
	my $cwd;

	%IP = %$ip;
	@ARGV = @$argv;

	### get the starting info
	$host = `hostname`;
	$cwd  = `pwd`;
	$csdt = `date +'%Y:%j:%H:%M:%S'`;
	chomp($csdt);
	chomp($host);
	chomp($cwd);



	### print the program header and ext progs info
	if( $IP{VerboseLevel} >= 0 ){
		print "#==================================================================\n";
		print "# START $IP{Prog} @ $csdt =+=+=+=+=+=+=+=+=+\n";
		print "#  Generating  $IP{Prog} Products\n";
		print "#  Cmdline: $0  $IP{CmdLine}\n";
		print "#  Run Time: $csdt\n";
		print "#  Machine: $host\n";
		print "#  Runtime Directory: $cwd\n";
		print "#\n";
		print "#\n";
		print "#===================================================\n";
		print "# Print Program(s) Location and  Version:\n" ;
		print "#  Time:$csdt\n";
		print "#   Program  - Version\n" ;
		print "#   ----------------------------------------------------\n";
		# OS
		$P    = "OS";
		chomp($P);
		$PRCS = `cat /etc/issue`;
		$PRCS = `uname -a`;
		chomp($PRCS);
		$PRCS =~ s/\n/ /g;
		print "#   $P - $PRCS\n";

		# perl
		$P    = `which perl`;
		chomp($P);
		$PRCS = `perl --version | egrep '(version|^This)'`;
		chomp($PRCS);
		@a    = split(' ',$PRCS);
		print "#   $P - $a[3]\n";
	
		# md5sum
		$P    = `which md5sum`;
		chomp($P);
		$PRCS = `md5sum --version | grep md5sum`;
		chomp($PRCS);
		@a    = split(' ',$PRCS);
		print "#   $P - $a[$#a]\n";
	
		# this prog
		$P    = `which $IP{Prog}`;
		chomp($P);
		print "#   $P - $IP{Version}\n";
		print "#\n";
		print "#\n";
	}

	return(0);
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
	print "usage: $IP{Prog} [Options]\n";
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
	print " Exit Return Value: $$rv{ReturnValue}\n";
	print "\n";

	exit($RV{ReturnValue});

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
	$$rv{Program}      = "t2.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 't2.pl';
	$$ip{Description} = 'Program description goes here';
	$$ip{CmdLine}     = "@ARGV";
	$$ip{Version}     = '$Rev$';
	$$ip{PrintVersion}= 0;
	$$ip{DebugLevel}  = 0;
	$$ip{VerboseLevel}= 0;
	$$ip{PS}          = '1-5';
	$$ip{PSMax}       = 5;
	$$ip{Help}        = 0;

	# program specific input parameters
	$$ip{ip}          = 'localhost';
	$$ip{port}        = 40000;
	$$ip{timeout}     = 20;


	### get the command line options
	if( GetOptions(
			"ip=s"        => \$$ip{ip},
			"port=s"      => \$$ip{port},
			"timeout=s"   => \$$ip{timeout},
			"home=s"      => \$$ip{home},
			"ps=s"        => \$$ip{PS},
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

	### go home
	return($$rv{ReturnValue});

}

#===================================================================
sub ValidateIP {

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


	# Return Value Structure
	$RV{Subroutine}   = "ValidateIP";
	$RV{Section}      = "";
	$RV{ErrorMessage} = "";
	$RV{ReturnValue}  = 0;



	### check for a print version request
	if( $$ip{PrintVersion} == 1 ){
		print "$$ip{Prog}\t$$ip{Version}\n";
		$RV{ReturnValue}  = 0;
		exit($RV{ReturnValue});
	}


	### check for a print help request
	if( $$ip{Help} == 1 ){
		$rv = PrnUsage($argv, $ip);
		$RV{ReturnValue}  = 0;
		exit($RV{ReturnValue});
	}



	### go home
	return($RV{ReturnValue});

}




#=============================================================================
sub ProcOptions {

	my ($argv, $ip) = @_;

	my @a;
	my $rv;
	my $i;
	my $j;


	$#a = -1;
	for ($i=0; $i<=$#$argv; $i++){

		$j = $i+1;


		# process debug switch
		# Cmd --d lvl
		if( ($$argv[$i] eq "-d")      || 
			($$argv[$i] eq "--d")     ||
			($$argv[$i] eq "-debug")  ||
			($$argv[$i] eq "--debug") ){
				$i++;
				$$ip{Debug}  = $$argv[$i];
				next;
		}


		# process help switch
		# Cmd --h [arg]
		if( ($$argv[$i] eq "-h")     || 
			($$argv[$i] eq "--h")    ||
			($$argv[$i] eq "-help")  ||
			($$argv[$i] eq "--help") ){
				$i++;
				$$ip{Help}  = 1;
				next;
		}


		# list all observatory commands
		if( ($$argv[$i] eq "-listobscmds") || 
			($$argv[$i] eq "--listobscmds") ){
				$$ip{listobscmds}  = 1;
				next;
		}

		# list all observatory subsystems
		if( ($$argv[$i] eq "-listobsss") || 
			($$argv[$i] eq "--listobsss") ){
				$$ip{listobsss}  = 1;
				next;
		}

		# list all subsystem commands
		# Cmd -listsscmds ss
		if( ($$argv[$i] eq "-listsscmds") || 
			($$argv[$i] eq "--listsscmds") ){
				$$ip{listsscmds} = 1;
				$$ip{ss}         = $$argv[$i+1];
				next;
		}






		if( $$argv[$i] eq "-v"){
			$$ip{Version}  = 1;
			next;
		}

		if( $$argv[$i] eq "--v"){
			$$ip{Version}  = 1;
			next;
		}



		if( $$argv[$i] eq "-version"){
			$$ip{Version}  = 1;
			next;
		}

		if( $$argv[$i] eq "--version"){
			$$ip{Version}  = 1;
			next;
		}




		if( $$argv[$i] eq "-noexec"){
			$$ip{Exec}  = 0;
			next;
		}

		if( $$argv[$i] eq "--noexec"){
			$$ip{Exec}  = 0;
			next;
		}


		if( $$argv[$i] eq "-n"){
			$$ip{Exec}  = 0;
			next;
		}

		if( $$argv[$i] eq "--n"){
			$$ip{Exec}  = 0;
			next;
		}





		push(@a, $$argv[$i]);
#print "at bottom $argv[$i] = $$argv[$i]\n";
#print "$argv = @$argv\n";
#print "\@a  = @a\n\n";
		
	}

#print "START ARGV = [$#$argv] @$argv\n";
$#$argv = -1;
@$argv  = (@a);
#print "END   ARGV = [$#$argv] @$argv\n";

#	print "
#	d|debug   => $$ip{Debug},
#	h|help    => $$ip{Help},
#	v|version => $$ip{Version},
#	noexec    => $$ip{Exec},
#	home=s    => $$ip{IGSS_HOME},
#	";



	return(0);

}



