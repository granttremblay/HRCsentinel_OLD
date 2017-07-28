#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 10/5/2016, P Nulsen:
# Common code moved to checkFotCLP, tidied.
# Test that code matches command.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 1.2 $';
our $Description = 'Check for discrete HV commanding.';

my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);


# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);


### The HV cmd list
my @CmdList = qw (2SPHVOF
		  2SPHVON   
		  2SPTTHV   
		  2SPTBHV   
		  2IMHVOF   
		  2IMHVON   
		  2IMTTHV   
		  2IMTBHV);

# Map command name to code
my %cdl;
@cdl {@CmdList} = qw (sd0100
		      xyzzyy
		      sd0200
		      sd0300
		      sd0900
		      xyzzyy
		      sd0a00
		      sd0b00);


my $ne = 0;
my %ERR;
foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 4;

    # shorten the line by replacing white spaces with a single space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    # Reports 2SPHVON and 2IMHVON as errors
    my $cmd = $a [3];
    if (defined $cdl {$cmd}) {
	# Checks that code matches command
	next if $a [7] eq $cdl {$cmd};
	$ERR{$ne++} = "Found HRC HV Cmd in line: $L2\n";
    }
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
    for (my $j = 0; $j < $ne; $j++){
	print " --- Error [$j]\n";
	print " $ERR{$j}\n";
	print "\n";
    }
}

exit ($ne);
