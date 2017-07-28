#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 5/20/2016, P Nulsen:
# Common code moved to checkFotCLP, rest tidied.
#
# Added inRadiationZone() to check reliably whether Chandra is in
# the radzone at the start of the load.
#
# Print the .hrcsel line that triggers an error.
#
#===========================================================================

use strict;
use warnings;
use checkFotCLP;


our $Description = 'Check for MCP and shield HV down in radiation zone.';
our $Version = '$Revision: 2.0 $';

my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

my $debug = $IP {DebugLevel};
my $os = 0;   # one shot error flag
my $ftt = 1;   # first time thru flag
my $ne  = 0;   # number of errors
my $nt  = 0;  # number of transitions

my %RAD;
$RAD {$nt}{State} = 0;
$RAD {$nt}{Line}  = "NA";

my %SHLD; 
$SHLD {$nt}{State}= 0;
$SHLD {$nt}{Line} = "NA";

my %HVI;
$HVI {$nt}{State} = 0;
$HVI {$nt}{Line}  = "NA";

my %HVS;
$HVS {$nt}{State} = 0;
$HVS {$nt}{Line}  = "NA";

my %ERR;
if ($debug) {print "### Starting Readline:\n";}

foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp($L);
    my @a = split (" ", $L);
    next if @a < 2;

    if ($ftt) {
	### first time thru, check for initial HV states
	if ($L =~ m/HVI = /) {
	    # MCP I high voltage
	    if ($a [-1] =~ m/off/ || $a [-1] =~ m/1\/2/) {
		$HVI {$nt}{State} = 0;
		$HVI {$nt}{Line}  = " Initial HVI Load Starting With $HVI{$nt}{State}  $L";
	    } elsif ($a [-1] =~ m/up/) {
		$HVI {$nt}{State} = 1;
		$HVI {$nt}{Line}  = " Initial HVI Load Starting With $HVI{$nt}{State}  $L";
	    }
	    if ($debug) { print "  HVI:$HVI{$nt}{Line}\n";}

	} elsif	($L =~ m/HVS = /) {
	    # MCP S high voltage
	    if ($a [-1] =~ m/off/ || $a [-1] =~ m/1\/2/) {
		$HVS {$nt}{State} = 0;
		$HVS {$nt}{Line}  = " Initial HVS Load Starting With $HVS{$nt}{State}  $L";
	    } elsif ($a [-1] =~ m/up/) {
		$HVS {$nt}{State} = 1;
		$HVS {$nt}{Line}  = " Initial HVS Load Starting With $HVS{$nt}{State}  $L";
	    }
	    if ($debug) {print "  HVS:$HVS{$nt}{Line}\n";}

	} elsif	($L =~ m/SHLD2PWR = /) {
	    # Shield high voltage
	    if ($a [-1] =~ m/off/) {
		$SHLD {$nt}{State} = 0;
		$SHLD {$nt}{Line}  = " Initial SHLDHV Load Starting With $SHLD{$nt}{State}  $L";
	    } elsif ($a [-1] =~ /on/) {
		$SHLD {$nt}{State} = 1;
		$SHLD {$nt}{Line}  = " Initial SHLDHV Load Starting With $SHLD{$nt}{State}  $L";
	    }
	    if ($debug) {print "  SHLD:$SHLD{$nt}{Line}\n";}

	} elsif	($L =~ m/RADMON = /) {
	    # PEJN: Check if in the rad zone, even though we no longer
	    # rely on the initial radmon state for this
	    my $t;
	    $RAD {$nt}{State} = &inRadiationZone (\@HRCSEL, \$t);
	    chomp ($t);
	    $t =~ s/\h+/ /g;
	    $RAD {$nt}{Line} = " Initial Load Starting With $RAD{$nt}{State}  $t";
	    if ($debug) {print "  RAD:$RAD{$nt}{Line}\n";}

	} elsif ($L =~ m/FIRST Command in Load/) {
	    $ftt = 0;
	    if ($debug) {print "### end of init section\n\n";}

	}

    ### end of init
    } else {

	if ($L =~ m/ELECTRON 1 RADIATION ENTRY 0/) { 
	    # Record RADIATION ENTRY 
	    $os = 0;  # Reset one shot flag
	    $nt++;
	    $SHLD {$nt}{State} = $SHLD {$nt-1}{State};
	    $HVI {$nt}{State}  = $HVI {$nt-1}{State};
	    $HVS {$nt}{State}  = $HVS {$nt-1}{State};

	    $RAD {$nt}{State} = 1;
	    $RAD {$nt}{Line}  = $L;
	    if ($debug) {print "\nRAD Entry at:[$nt]  $a[0]\n";}
	    
	} elsif ($L =~ m/ELECTRON 1 RADIATION EXIT/) {
	    # Record RADIATION EXIT
	    $os = 0;  # Reset one shot flag
	    $nt++;
	    $SHLD {$nt}{State} = $SHLD {$nt-1}{State};
	    $HVI {$nt}{State}  = $HVI {$nt-1}{State};
	    $HVS {$nt}{State}  = $HVS {$nt-1}{State};

	    $RAD {$nt}{State} = 0;
	    $RAD {$nt}{Line}  = $L;
	    if ($debug) {print "RAD Exit  at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/2S1HVON/ || $L =~ m/2S2HVON/) { 
	    # SHLD 1 or 2 turned on
	    $SHLD {$nt}{State} = 1;
	    $SHLD {$nt}{Line}  = $a[0];
	    if ($debug) {print "SHLD on   at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/2S1HVOF/ || $L =~ m/2S2HVOF/) { 
	    # SHLD 1 or 2 HV  turned off
	    $SHLD {$nt}{State} = 0;
	    $SHLD {$nt}{Line}  = $a[0];
	    if ($debug) {print "SHLD off   at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/ENABLE SCS 0x59/) { 
	    # HRC-I ramp up enabled
	    $HVI {$nt}{State} = 1;
	    $HVI {$nt}{Line}  = $a[0];
	    if ($debug) {print "HVI EN ramp up at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/DISABLE SCS 0x59/) { 
	    # HRC-I ramp up disabled
	    $HVI {$nt}{State} = 0;
	    $HVI {$nt}{Line}  = $a[0];
	    if ($debug) {print "HVI DS ramp up at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/ENABLE SCS 0x5A/) { 
	    # HRC-S ramp up enabled
	    $HVS {$nt}{State} = 1;
	    $HVS {$nt}{Line}  = $a[0];
	    if ($debug) {print "HVS EN ramp up at:[$nt]  $a[0]\n";}

	} elsif ($L =~ m/DISABLE SCS 0x5A/) { 
	    # HRC-S ramp up disabled
	    $HVS {$nt}{State} = 0;
	    $HVS {$nt}{Line}  = $a[0];
	    if ($debug) {print "HVS DS ramp up at:[$nt]  $a[0]\n";}

	}

	# In the rad zone, if any HV is up or enabled, flag an error.
	if ($RAD {$nt}{State}) {
	    if ($SHLD {$nt}{State} || $HVI{$nt}{State} || $HVS{$nt}{State}) {
		if ($os == 0) {
		    if ($debug) {print "   $L\n";}
		    # Save the line, error message and radmon transition number
		    $ne++;
		    $ERR {$ne}{CMD} = $L;
		    $ERR {$ne}{LINE} = "Shld=$SHLD{$nt}{State}; HVI=$HVI{$nt}{State}; ; HVS=$HVS{$nt}{State};";
		    $ERR {$ne}{NT} = $nt;
		    if ($debug) {print "   Err# $ne; found error [@ transition $nt] 	$ERR{$ne}{LINE}\n\n";}
		    $os = 1;  # Prevent further error reports for this passage
		}
	    }
	}
    }
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne HRC HV active after radiation entry:\n";
    for (my $j = 1; $j <= $ne; $j++){
	print "Error [$j]\n";
	$nt = $ERR{$j}{NT};
	print " $RAD{$nt}{Line}\n";
	# PEJN: error print added
	print "   $ERR{$j}{CMD}\n";
	print "    $ERR{$j}{LINE}\n";
	$nt++;
	print " $RAD{$nt}{Line}\n";
	print "\n";
    }
}

exit ($ne);
