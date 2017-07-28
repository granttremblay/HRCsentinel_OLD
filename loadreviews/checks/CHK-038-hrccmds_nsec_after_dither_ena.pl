#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/31/2016, P Nulsen:
# Removed code now in checkFotCLP and tidied.
#
# Use vcduCmp() to compute vcdu differences.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Delay from HRC HV ramp up to next HRC cmd.';

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
my $ftt = 1;   # First time through - collecting initial state
my $ne = 0;   # number of errors
my $HRCactive = 0;   # From SCS 91 activation to next 2NXILASL or SCS 91 term

my %DITHER;
my %SCS91;

$SCS91 {State} = 0;
$SCS91 {Line} = "NA";

foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp($L);
    my @a = split (" ", $L);
    next if @a < 2;

    # Remove redundant white space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    my @CSDT = split(':', $a[0]);

    if ($ftt) {
	if ($L =~ m/^   vcdu = /) {
	    ### get vcdu value from initial state vector
	    $DITHER {vcdu} = $a[2];
	    $SCS91 {vcdu} = $a[2];
	    if ($debug) {print "Initial State [vcdu=$a[2]]\n";}

	} elsif ($L =~ m/^   FMT = /) {
	    # Assume format 1 initially means the HRC is active
	    # - may cause some spurious flagging of errors, but safer
	    $HRCactive = 1;

	} elsif ($L =~ m/^   DITHER = /) {
	    ### get dither state from initial state vector
	    $DITHER {State} = $a[2];
	    $DITHER {Line} = $L;
	    if ($debug) {print "Initial State [Dither=$DITHER{State}]\n";}

	} elsif ($L =~ m/^   SCS91 = /) {
	    ### get scs91 state from initial state vector
	    $SCS91 {Line}  = $L;
	    $SCS91 {State} = $a[2];
	    if ($debug) {print "Initial State [scs91=$SCS91{State}]\n";}

	} elsif ($L =~ m/FIRST Command in Load/) {
	    $ftt = 0;

	}
    } else {

	if ($L =~ m/SCS 0x5B/) {
	    ### HRC dither control - scs91
	    if ($a[6] =~ m/ACTIVATE/) {
		$SCS91 {State} = "act";
		$SCS91 {Line} = $L;
		$SCS91 {vcdu}  = $a[2];
		# Always activated late in the setup of an HRC observation
		$HRCactive = 1;
	    } elsif ($a[6] =~ m/TERMINATE/) {
		$SCS91 {State} = "term";
		$SCS91 {Line} = $L;
		$SCS91 {vcdu} = $a[2];
		# Redundant?
		$HRCactive = 0;
	    }
	    if ($debug) {print "SCS 91 $SCS91{State} HRC Dither control at:$L2\n";}

	} elsif ($L =~ m/AOENDITH/) {
	    ### HRC dither enable
	    if ($debug) {print "HRC Dither enable at:$L2\n";}
	    $DITHER {vcdu} = $a[2];
	    $DITHER {Line} = $L;
	    $DITHER {State} = "en";

	} elsif ($SCS91 {State} =~ m/act/ && $DITHER {State} =~ m/en/ 
		 && @CSDT == 5) {
	    # Check for HRC commands while SCS91 is active and dither enabled
	    if (!defined ($a[3])) {
		print "Problem: $L\n";

	    } elsif ($a[3] =~ m/^2/) {
		# VCDU when HV ramp up would have started
		my $act_vcdu;
		if (vcduCmp ($DITHER {vcdu}, $SCS91 {vcdu}) >= 0) {
		    $act_vcdu = $DITHER {vcdu};
		} else {
		    $act_vcdu = $SCS91 {vcdu};
		}
		my $hrcvcdu = $a[2];
		my $dvcdu = vcduCmp ($hrcvcdu, $act_vcdu);
		my $dsec = 0.25 * $dvcdu;
	
		if ($debug) {
		    print "\n  hrccmd: [91=$SCS91{State}] [D=$DITHER{State}]:($dsec): $L2\n\n";
		}
		##### takes 205 seconds to get to HV
		if ($HRCactive && $dsec < 250) {
		    # HRC commands < 250 sec after HV ramp up starts
		    printf("    %5.1f: %s\n", $dsec, $L2);
		    $ne++;
		}

		if ($a[3] =~ m/2NXILASL/) {
		    # HRC observation ends
		    $HRCactive = 0;
		}
	    }
	}
    }
} ### end of read hrcsel loop


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
}

exit ($ne);

