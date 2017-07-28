#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:
#
# 10/5/2016, P Nulsen:
# Factored code in checkFotCLP, tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 1.2 $';
our $Description = 'Check hv scs for selected detector.';

my %IP;
my %RV;


### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);


# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/vehicle/$IP{ID}.vehicle.hrcsel", \@HRCSEL);

my $debug = $IP {DebugLevel};
my $ne = 0;   # number of errors
my @ERR;

### begin master loop of .hrcsel file
foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 2;

    # shorten the line by replacing white spaces with a single space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    if ($L =~ /ACTIVATE SCS 0x5[CD] \((9[23])\) HRC-([IS]) HV On/) {
	# HRC I or S HV on
	my $scs = $1;
	my $det = $2;
	++$ne;
	$ERR[$ne] = "SCS $scs HV$det on at:$L2\n";
	if ($debug) {print "SCS $scs, HV$det on at:$L2\n";}

    } elsif ($L =~ m/SCS 0x5[789A] \((8[789]|90)\) HRC-([IS]) HV Ramp (Up|Down)/) {
	# HRC I or S HV ramp up or down
	my $scs = $1;
	my $det = $2;
	my $dir = lc ($3);
	$ne++;
	$ERR[$ne] = "SCS $scs HV$det ramp $dir at:$L2\n"; 
	if ($debug) {print "SCS $scs, HV$det ramp $dir at:$L2\n";}

    } elsif ($L =~ m/SCS 0x5B \(91\) HRC Dither Control/) {
	# HRC dither control - scs 91
	my $scs = 91;
	$ne++;
	$ERR[$ne] = "SCS $scs HRC Dither control at:$L2\n"; 
	if ($debug) {print "SCS $scs, HRC Dither control at:$L2\n";}

    }
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne hrc specific scs's called in vehicle loads:\n";
    for (my $j = 1; $j <= $ne; $j++){
	print "Error [$j]\n";
	print " $ERR[$j]\n";
	print "\n";
    }
}

exit ($ne);
