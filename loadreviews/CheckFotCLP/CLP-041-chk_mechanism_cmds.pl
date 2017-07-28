#!/usr/bin/perl -w

#===========================================================================
#
#    J. Chappell (jhc)
#
#    Program: CLP-041-chk_mechanism_cmds.pl
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
	my $nw;
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
	my %ERRW;
	my %SCS;
	my %HV;
	my %PREAMPA;
	my %FORMATS;
	my %FORMATH;
	my %RADMON;
	my %OBS;

	my @WarnList;
	my @CmdList;
	my $mechcmd;
	my %CmdDes;

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



 	@WarnList = qw(
		2PSHBALD  
 		2PSLBALD 
 		2SMOIAEN 
 		2SMOTAEN 
 		2CHPLAEN 
 		2CHSLAEN 
 		2OMPLAEN 
 		2OMSLAEN 
 		2STFLAEN 
	);


	### define the mech cmd list
	@CmdList = qw( 
		2FSMREN  
		2FSMRDI  
		2FSCSEN  
		2FSCSDI  
		2FSPYEN  
		2FSPYDI  
		2SMOIADI 
		2SMOTADI 
		2CHPLADI 
		2CHSLADI 
		2OMPLADI 
		2OMSLADI 
		2STFLADI 
		2MDRVADI 
		2MDRVAEN 
		2MVPSAEX 
		2MVLAAEX 
		2MVLBAEX 
		2NSTAAEX 
		2NSTBAEX 
		2MCMRASL 
		2ALMTADS 
		2DRMTASL 
		2CLMTASL 
		2PYMTASL
		2NYMTASL 
	);


#	$CmdDes{2FSMREN} = "FAILSAFE MASTER RELAY ENABLE";
#	$CmdDes{2FSMRDI} = "FAILSAFE MASTER RELAY DISABLE";
#	$CmdDes{2FSCSEN} = "FAILSAFE CALSRC RELAY ENABLE";
#	$CmdDes{2FSCSDI} = "FAILSAFE CALSRC RELAY DISABLE";
#	$CmdDes{2FSPYEN} = "FAILSAFE +Y SHUTTER ENABLE";
#	$CmdDes{2FSPYDI} = "FAILSAFE +Y SHUTTER DISABLE";
#	$CmdDes{2FSNYEN} = "FAILSAFE -Y SHUTTER ENABLE";
#	$CmdDes{2FSNYDI} = "FAILSAFE -Y SHUTTER DISABLE";
#	$CmdDes{2PSHBALD} = "MOT CTRL POS WORD HI BYTE LOAD";
#	$CmdDes{2PSLBALD} = "MOT CTRL POS WORD LO BYTE LOAD";
#	$CmdDes{2SMOIADI} = "SELECTED MTR OVERCUR PROT DISA";
#	$CmdDes{2SMOIAEN} = "SELECTED MTR OVERCUR PROT ENAB";
#	$CmdDes{2SMOTADI} = "SELECTED MTR OVERTEM PROT DISA";
#	$CmdDes{2SMOTAEN} = "SELECTED MTR OVERTEM PROT ENAB";
#	$CmdDes{2CHPLADI} = "CLOS/HOME PRIMARY LIM SW DISA";
#	$CmdDes{2CHPLAEN} = "CLOS/HOME PRIMARY LIM SW ENAB";
#	$CmdDes{2CHSLADI} = "CLOS/HOME SECON LIM SW DISA";
#	$CmdDes{2CHSLAEN} = "CLOS/HOME SECON LIM SW ENAB";
#	$CmdDes{2OMPLADI} = "OPEN/MAX PRIMARY LIM SW DISA";
#	$CmdDes{2OMPLAEN} = "OPEN/MAX PRIMARY LIM SW ENAB";
#	$CmdDes{2OMSLADI} = "OPEN/MAX SECON LIM SW DISA";
#	$CmdDes{2OMSLAEN} = "OPEN/MAX SECON LIM SW ENAB";
#	$CmdDes{2STFLADI} = "CLEAR STOP FLAGS";
#	$CmdDes{2STFLAEN} = "ENABLE STOP FLAGS";
#	$CmdDes{2MDRVADI} = "MOTOR DRIVE DISABLE";
#	$CmdDes{2MDRVAEN} = "MOTOR DRIVE ENABLE";
#	$CmdDes{2MVPSAEX} = "STEP FM HOME TO POS CTR VALUE";
#	$CmdDes{2MVLAAEX} = "MOVE TO CLOS/HOME LIM SWITCH";
#	$CmdDes{2MVLBAEX} = "MOVE TO OPEN/MAX LIMIT SWITCH";
#	$CmdDes{2NSTAAEX} = "MOVE N STEPS TWRD CLOS/HOM LS";
#	$CmdDes{2NSTBAEX} = "MOVE N STEPS TWRD OPEN/MAX LS";
#	$CmdDes{2MCMRASL} = "MOTION CONTROL MODE RESET";
#	$CmdDes{2ALMTADS} = "ALL MOTORS DESELECT";
#	$CmdDes{2DRMTASL} = "DOOR MOTOR SELECT";
#	$CmdDes{2CLMTASL} = "CALSRC MOTOR SELECT";
#	$CmdDes{2PYMTASL} = "+Y SHUTTER MOTOR SELECT";
#	$CmdDes{2NYMTASL} = "-Y SHUTTER MOTOR SELECT";
#
#
	### begin master loop of .hrcsel file
	$nr = -1;
	$ne = 0;
	$nw = 0;
	foreach $L (@HRCSEL){

		$nr++;

		# remove the cr and split the line on white spaces
		chomp($L);
		@a    = split(" ",$L);
		if( $#a <= 0 ){ next; }

		# shorten the line by replacing white spaces with a single space
		$L2 = $L;
		$L2 =~ s/ +/ /g;
		$L2 =~ s/	+/ /g;

		# check for scs 105 enable/activation command
		if( $L2 =~ m/ \(105\) / ){
			$ERR{$ne++} = "Found SCS 105 Cmd in line: $L2\n";
		}

		# loop thru each motor commands and check for cmd in current line
		foreach $mechcmd (@CmdList){
			if( $L2 =~ m/\Q$mechcmd/ ){
				$ERR{$ne++} = "Found Mech Cmd [$mechcmd] in line: $L2\n";
				#print "hit ===============\n";
				#print "Current Line: $L\n";
				#print "Current Line: $L2\n";
				#print "Current mechcmd: $mechcmd\n";
			}
		}

		
		foreach $mechcmd (@WarnList){
			if( $L2 =~ m/\Q$mechcmd/ ){
				print "Warn: Found Mech Cmd [$mechcmd] in line: $L2\n";
				$ERRW{$nw++} = "Warn: Found Mech Cmd [$mechcmd] in line: $L2\n";
				#print "hit ===============\n";
				#print "Current Line: $L\n";
				#print "Current Line: $L2\n";
				#print "Current mechcmd: $mechcmd\n";
			}
		}

	} ### end of read hrcsel loop





	if( $ne == 0 ){
		print "[OK]   $IP{Prog}\n";
	}else{
		print "[FAIL] $IP{Prog}\n";
		print " Found $ne configuration errors:\n";
		for($j=0; $j<$ne; $j++){
			print " --- Error [$j]\n";
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
	$$rv{Program}      = "CLP-041-chk_mechanism_cmds.pl";
	$$rv{Subroutine}   = "GetIP";
	$$rv{Section}      = "";
	$$rv{ErrorMessage} = "";
	$$rv{ReturnValue}  = 0;

	# general input parameters
	$$ip{Prog}        = 'CLP-041-chk_mechanism_cmds.pl';
	$$ip{Description} = 'Check Mechanisms.';
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






