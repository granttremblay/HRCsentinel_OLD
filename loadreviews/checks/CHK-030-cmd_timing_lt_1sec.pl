#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/30/2016, P Nulsen: 
# Common code moved to checkFotCLP module.
# Reformatted and other tidying.
# 10/24/2016, P Nulsen:
# Add check for vcdu roll over.
#
#===========================================================================

use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Check HRC 1 sec command timing requirement.';


my %IP;
my %RV;

### Get/Set the command Parameters (IP).
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# Read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

# VCDU counter is 24 bits
my $rollover = 1 << 24;
my $ne = 0;
my @ERR;
foreach my $L (@HRCSEL) {
    # Check lines with small dvcdu flagged by fotclp2hrcclp
    if ($L =~ m/VCDU WARN: dvcdu/) {
	my @a = split (" ", $L);
	# Error only for dvcdu < 3
	my $dvcdu = $a [-1];
	if ($dvcdu < 3) {
	    # Roll over subtracts 2^{24} from vcdu, making
	    # dvcdu negative
	    if ($dvcdu >= 0 || $dvcdu + $rollover < 3) {
		$ne++;
		chomp ($L);
		$ERR [$ne] = $L;
	    }
	}
    } 
}

if ($ne == 0) {
    print "[OK]  $IP{Prog}\n";
} else {
    print "[FAIL]$IP{Prog}\n";
    for (my $i = 1; $i <= $ne; $i++){
	print " $i: $ERR[$i]\n";
    }
}

exit ($ne);
