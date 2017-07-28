#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 10/5/2016, P Nulsen:
# Common code moved to checkFotCLP, tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 1.2 $';
our $Description = 'Check Mechanisms.';

my @WarnList = qw (2PSHBALD
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
my @CmdList = qw(2FSMREN  
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


my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);


### begin master loop of .hrcsel file
my $ne = 0;
my %ERR;

foreach my $L (@HRCSEL) {

    # split the line on white spaces
    my @a = split (" ", $L);
    next if @a < 2;

    # shorten the line by replacing white spaces with a single space
    chomp ($L);
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    # check for scs 105 enable/activation command
    if ($L2 =~ m/ \(105\) /) {
	$ERR {$ne++} = "Found SCS 105 Cmd in line: $L2\n";
    }

    # Checks for motor commands
    if (@a > 4) {
	# Position of the command in the line assumed fixed
	my $cmdword = $a[3];

	if (my @hits = grep ($_ eq $cmdword, @CmdList)) {
	    $ERR {$ne++} = "Found Mech Cmd [$hits[0]] in line: $L2\n";
	}

	if (my @hits = grep ($_ eq $cmdword, @WarnList)) {
 	    print "Warn: Found Mech Cmd [$hits[0]] in line: $L2\n";
	}
    }

} ### end of read hrcsel loop


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
    for (my $j = 0; $j < $ne; $j++) {
	print " --- Error [$j]\n";
	print " $ERR{$j}\n";
	print "\n";
    }
}

exit ($ne);
