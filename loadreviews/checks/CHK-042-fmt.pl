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
our $Description = 'Check spacecraft and HRC formats.';

my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);


# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

my %FORMATS;  # Spacecraft format
my %FORMATH;  # HRC format

my $debug = $IP {DebugLevel};
my $ftt = 1;   # first time thru flag
my $Flag = 0;   # active hrc detector flag

my %OBS;
$OBS {ID} = -1;

my $ne = 0;
my %ERR;


foreach my $L (@HRCSEL){

    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 2;

    # replace white space with a single space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    if ($ftt) {
	### get initial FORMAT
	if ($L =~ m/FMT = /) {
	    $FORMATS {State} = $a[2];
	    $FORMATH {State} = $a[2];
	    $FORMATS {Line} = "initial state $L";
	    $FORMATH {Line} = "initial state $L";
	    if ($debug) {
		print "  FORMAT: $FORMATS{Line}\n";
	    }
	    $ftt = 0;
	}

    } else {

	if ($L =~ m/^OBSID =/) {
	    ### OBS ID 
	    $OBS {ID} = substr ($a[2], 0, -1);
	    if ($debug) {
		print "\n==================================";
		print "\nOBS ID: $OBS{ID}; ";
		print "Current fmt: $FORMATS{State}\n";
	    }
	    delete $OBS {SI};

	} elsif ($L =~ m/SI =/) {
	    ### OBS SI 
	    $OBS {SI} = $a[2];
	    if ($debug) {print "OBS SI: $OBS{SI}\n";}
	    $Flag = ($OBS {SI} =~ /HRC/);

	} elsif ($L =~ m/CSELFMT/) {
	    ### S/C FORMATS CHANGE
	    $FORMATS {State} = $a [-1];
	    $FORMATS {Line} = $L;
	    if ($debug) {print "FORMAT S/C SET $FORMATS{State}  at:$L2\n";}

	} elsif ($L =~ m/2OBSVASL/) {
	    ### HRC FORMATS CHANGE
	    $FORMATH {State} = "1";
	    $FORMATH {Line} = $L;
	    if ($debug) {print "FORMAT HRC SET $FORMATH{State}  at:$L2\n";}

	} elsif ($L =~ m/2NXILASL/) {
	    ### HRC FORMATS CHANGE
	    $FORMATH {State} = "NIL";
	    $FORMATH {Line} = $L;
	    if ($debug) {print "FORMAT HRC SET $FORMATH{State}  at:$L2\n";}

	} elsif ($L =~ m/ACTIVATE SCS 0x5B/) {
	    # Check formats when HRC dither control (SCS 91) is activated.
	    # This happens at the outset of every HRC observation.
	    if ($debug && $Flag == 1) {print "   START OBS: fmth=$FORMATH{State};  fmts=$FORMATS{State} at:$L2\n";}
	    # Whenever SCS 91 is activated, it should be the start of an HRC
	    # observation
	    if (!exists $OBS {SI}) {
		# OR info missing for this ObsID - no check
		print "  ***WARNING*** No OR info for ObsID $OBS{ID}\n";
	    } elsif (!$Flag) {
		# SCS 91 activated, but not an HRC ObsID
		if ($debug) {print "Activated SCS 91 for non-HRC ObsID $OBS{SI} at:$L2\n";}
		$ERR {$ne++} = "Activated SCS 91 for non-HRC ObsID $OBS{SI} at:$L2\n";
	    } elsif ($FORMATH {State} ne "1") {
		# HRC ObsID, but HRC format not set
		if ($debug) {print "START HRC OBS: fmt hrc=($FORMATH{State} != 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";}
		$ERR {$ne++} = "START HRC OBS: fmt hrc=($FORMATH{State} != 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";
	    } elsif ($FORMATS {State} != 1) {
		# HRC observing, but satellite format not 1
		if ($debug) {print "START HRC OBS: fmt hrc=($FORMATH{State} == 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";}
		$ERR {$ne++} = "START HRC OBS: fmt hrc=($FORMATH{State} == 1);  fmt s/c=($FORMATS{State} != 1) at:$L2\n";
	    }
	}
    }
} ### end of read hrcsel loop


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
    for (my $j = 1; $j <= $ne; $j++) {
	print "Error [$j]\n";
	print " $ERR{$j}\n";
	print "\n";
    }
}

exit ($ne);
