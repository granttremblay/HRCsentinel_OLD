#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
# 10/5/2016, P Nulsen:
# Filtered common code and tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 1.2 $';
our $Description = 'Check for HRC spurious commands in the vehicle load.';


my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the vehicle .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/vehicle/$IP{ID}.vehicle.hrcsel", \@HRCSEL);

# HRC commands allowed in the vehicle load
my @VALIDCMDLST = qw (2NXILASL 2FIFOAON 2FIFOAOF 2OBSVASL);
# A hash with the valid commands as keys
my %valid;
@valid {@VALIDCMDLST} = @VALIDCMDLST;

my $nr = 0;
my $ne = 0;
my @ERR;

foreach my $L (@HRCSEL) {
    ++$nr;

    # remove the cr and split the line on white spaces
    chomp($L);
    my @a = split (" ", $L);

    next if @a < 4;

    # check all HRC commands
    if ($L =~ m/ == /) {
	if (!exists ($valid {$a[3]})) {
	    # Not in the set of valid HRC commands
	    $ERR[$ne] = "Invalid Command in vehicle load at line: $nr\n  $L\n";
	    ++$ne;
	}
    }
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    for (my $i = 0; $i < $ne; ++$i) {
	my $j = $i + 1;
	print " $j: $ERR[$i]\n";
	print "\n";
    }
}

exit($ne);
