#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/30/2016, P Nulsen:
# Common code move to checkFotCLP, rest tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Check for bad HRC command hex codes.';


my %IP;
my %RV;
my @ERR;

### Get/Set the runtime Input Parameters (IP)
ErrorExit(\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit(\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

my $ne = 0;

foreach my $L (@HRCSEL){
    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);

    if ($L =~ m/\!\=/) {
	$ne++;
	$ERR[$ne] = $L;
    } 
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    for (my $i = 1; $i <= $ne; $i++){
	print " $i: $ERR[$i]\n";
    }
}


exit ($ne);
