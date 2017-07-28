#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/31/2016, P Nulsen:
# Removed code in checkFotCLP and tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Check for pmt on and up after radiation belts';

my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);


# loop thru each line of the .hrcsel file
my $debug = $IP {DebugLevel};

my $FTT = 1;   # first command flag

my %CTV;
my %ERR;
my $ne = 0;   # number of errors
my $maxvcdu = 200;   # max vcdu counts allowed after radmon ena and hv =on and step=8

# Indicates when RADMON is enabled, but shield voltage step < 8.
# Used to ensure that the shield is turned on promptly, in case no 2S2STHV command
# is issued.
my $RadmonEnableTrigger = -1;

foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 2;;

    # eliminate multiple white spaces from the .hrcsel line
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    if ($FTT) {
	# Get radmon and shield status from the initial state vector
	if ($L =~ m/^   vcdu = /) {
	    ### initial vcdu value
	    $CTV {Shld2Step}{vcdu} = $a[2];
	    $CTV {RadmonEna}{vcdu} = $a[2];
	    $CTV {RadmonDis}{vcdu} = $a[2];
	    $CTV {Shld2Pwr}{vcdu} = $a[2];
	    if ($debug) {print "Initial  VCDU [vcdu=$a[2]]\n";}

	} elsif ($L =~ m/^   SHLD2PWR = /) {
	    ### initial state of radiation shield
	    $CTV {Shld2Pwr}{Line} = $L;
	    $CTV {Shld2Pwr}{State} = $a[2];
	    if ($debug) {print "Initial State [SHLD2PWR=$CTV{Shld2Pwr}{State}]\n";}

	} elsif ($L =~ m/^   SHLD2STEP = /) {
	    ### initial HV step of radiation shield
	    $CTV {Shld2Step}{Line} = $L;
	    $CTV {Shld2Step}{LastState} = $a[2];
	    $CTV {Shld2Step}{State} = $a[2];
	    if ($debug) {print "Initial State [SHLD2STEP=$CTV{Shld2Step}{State}]\n";}

	    # PEJN - SHLD2STEP comes after RADMON
	    if (defined ($CTV {RadmonEna}{State}) && $a[2] != 8) {
		# Initial RADMON state is enabled, but shield voltage is not up.
		# Should not happen, but just in case:
		$RadmonEnableTrigger = $CTV {RadmonEna}{vcdu};
	    }

	} elsif ($L =~ m/^   RADMON = /) {
	    ### initial radmon state
	    if ($a[2] =~ m/en/) {
		$CTV {RadmonEna}{State} = $a[2];
		$CTV {RadmonEna}{Line} = $L;
		if ($debug) {print "Initial State [RADMON=$CTV{RadmonEna}{State}]\n";}
	    } elsif ($a[2] =~ m/ds/) {
		$CTV {RadmonDis}{State} = $a[2];
		$CTV {RadmonDis}{Line} = $L;
		if ($debug) {print "Initial State [RADMON=$CTV{RadmonDis}{State}]\n";}
	    }

	} elsif ($L =~ m/FIRST Command in Load/) {
	    ### get initial first command state
	    if ($debug) {print "First command start: $a[0]\n\n";}
	    $FTT = 0;
	}

	# Finished processing initial state vector.
	# Follow events relevant to the shield state.

    } elsif ($L =~ m/Radmon Disable/) {
	### Radmon disable
	if ($debug) {print "Radmon Disable:            $L2\n\n";}
	$CTV {RadmonDis}{vcdu} = $a[2];
	$CTV {RadmonDis}{Line} = $L;
	$CTV {RadmonDis}{State} = 'ds';

	# check that shld pwr is not on when radmon is disabled.
	if ($CTV {Shld2Pwr}{State} =~ "on") {
	    $ERR {$ne++} = "Shield HV is on when radmon is disabled: @ vcdu = $CTV{RadmonDis}{vcdu}\n";
	}

	# check that shld step == 0 when radmon is disabled.
	if ($CTV {Shld2Step}{State} != 0) {
	    $ERR {$ne++} = "Shield HV step is not 0 when radmon is disabled: @ vcdu = $CTV{RadmonDis}{vcdu}\n";
	}

    } elsif ($L =~ m/Radmon Enable/) {
	### Radmon enable
	if ($debug) {print "Radmon Enable:             $L2\n";}
	$CTV {RadmonEna}{vcdu} = $a[2];
	$CTV {RadmonEna}{Line} = $L;
	$CTV {RadmonEna}{State} = 'en';

	# PEJN
	# Remember vcdu of RADMON enable until shield voltage is fully up
	$RadmonEnableTrigger = $a[2];

	# check if shld pwr is already on when radmon is enabled.
	if ($CTV {Shld2Pwr}{State} =~ "on") {
	    $ERR {$ne++} = "Shield HV is on when radmon is enabled: @ vcdu = $CTV{RadmonEna}{vcdu}\n";
	}

	# check if shld step != 0 when radmon is enabled.
	if ($CTV {Shld2Step}{State} != 0) {
	    $ERR {$ne++} = "Shield HV step is not 0 when radmon is enabled: @ vcdu = $CTV{RadmonEna}{vcdu}\n";
	}

    } elsif ($L =~ m/2S2HVOF/) {
	### HRC B shield off
	if ($debug) {print " HRC shield B pwr  off:    $L2\n";}
	$CTV {Shld2Pwr}{vcdu} = $a[2];
	$CTV {Shld2Pwr}{Line} = $L;
	$CTV {Shld2Pwr}{State} = "off";

    } elsif ($L =~ m/2S2HVON/) {
	### HRC B shield on
	if ($debug) {print " HRC shield B pwr   on:    $L2\n";}
	$CTV {Shld2Pwr}{vcdu} = $a[2];
	$CTV {Shld2Pwr}{Line} = $L;
	$CTV {Shld2Pwr}{State} = "on";

    } elsif ($L =~ m/2S2STHV/) {
	### HRC shield step changes
	$CTV {Shld2Step}{LastState} = $CTV {Shld2Step}{State};
	$CTV {Shld2Step}{vcdu} = $a[2];
	$CTV {Shld2Step}{Line} = $L;
	$a[8] =~ /\((\d+)\)/; # Remove parentheses around step
	$CTV {Shld2Step}{State} = $1;

	if ($debug) {print " HRC shield B step $CTV{Shld2Step}{LastState} -> $CTV{Shld2Step}{State}: $L2\n";}

	# check for more than a 4 step increase
	my $dsteps = $CTV {Shld2Step}{State} - $CTV {Shld2Step}{LastState};
	if ($dsteps > 4) {
	    $ERR {$ne++} = "Shield HV step increased (dsteps=$dsteps)  more than 4 steps @ vcdu = $CTV{Shld2Step}{vcdu}\n";
	}

	# check if radmon==en && step != 8 && dvcdu > maxvcdu  
	my $dvcdu = vcduCmp ($CTV {Shld2Step}{vcdu}, $CTV {RadmonEna}{vcdu});
	my $dsec = $dvcdu / 2.05;
	$dsec = sprintf ("%.2f", $dsec);
	if ($CTV {Shld2Step}{State} > 8) {
	    $ERR {$ne++} = "Shield HV step is ($CTV{Shld2Step}{State} > 8) @ vcdu = $CTV{Shld2Step}{vcdu}\n";
	} elsif ($CTV {Shld2Pwr}{State} =~ m/off/) {
	    if ($CTV {Shld2Step}{State} > 0) {
		$ERR {$ne++} = "Shield HV step is ($CTV{Shld2Step}{State} > 0) && (HV=off) @ vcdu = $CTV{Shld2Step}{vcdu}\n";
	    }
	} elsif ($CTV {Shld2Pwr}{State} =~ m/on/) {
	    if ($CTV {Shld2Step}{State} == 8) {		    
		if ($debug) {
		    print "     shield B step ($CTV{Shld2Step}{State}):     (\@max=8) after ($dsec sec)($dvcdu < $maxvcdu vcdu) after radmon ena\n\n";
		}

		# PEJN - all is dandy
		$RadmonEnableTrigger = -1;

	    } else {
		# Shield on at step < 8
		if ($dvcdu > $maxvcdu) {
		    $ERR {$ne++} = "Shield HV step is not upto step 8($CTV{Shld2Step}{State}) after ($dvcdu) $maxvcdu vcdu cnts @ vcdu = $CTV{Shld2Step}{vcdu}\n";
		}
	    }
	}	

    } elsif ($RadmonEnableTrigger >= 0 && @a > 5 && $a[5] eq "==") {
	# PEJN - on any HRC command, other than the 3 trapped above,
	# waiting for shield voltage to be turned on fully.
	my $dvcdu = vcduCmp ($a[2], $RadmonEnableTrigger);
	if ($dvcdu > $maxvcdu) {
	    $ERR {$ne++} = "Shield HV step not at step 8 ($CTV{Shld2Step}{State}) after $dvcdu cnts, @ vcdu = $a[2]\n";
	    $RadmonEnableTrigger = -1;
	}

    }
}


### print out errors
if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";

} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
    for (my $j = 0; $j < $ne; $j++) {
	print "Error [$j]\n";
	print " $ERR{$j}\n";
    }
}

exit ($ne);
