#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/30/2016, P Nulsen:
# Common code move to checkFotCLP and rest tidied.
#
#===========================================================================

use strict;
use warnings;
use checkFotCLP;


our $Description = 'Check for hrc cmds in radmon disable.';
our $Version = '$Revision: 2.0 $';


my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit(\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

# HRC commands allowed during RADMON disable
my @OKCMDLST = qw (2NXILASL 2FIFOAON 2FIFOAOF 2OBSVASL);
my %okRadmonDis;
foreach my $t (@OKCMDLST) {
    $okRadmonDis {$t} = 1;
}

my $ftt = 1;   # first time thru flag
my $ne  = 0;   # number of errors
my $nt  = -1;  # number of transitions

my %RADMON;
$RADMON {$nt}{State} = 0;
$RADMON {$nt}{Line} = "NA";
my %ERR;

foreach my $L (@HRCSEL) {

    # remove the cr and split the line on white spaces
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 2; # Skip lines with no command

    if ($ftt) {
	# Get radmon state from the initial state vector
	if ($L =~ m/RADMON = /) {
	    $nt++;
	    if ($a [-1] =~ m/ds/) {
		$RADMON {$nt}{State} = 0;
	    }else{
		$RADMON {$nt}{State} = 1;
	    }
	    $RADMON {$nt}{Line} = " Initial Load Starting With $L";

	} elsif ($L =~ m/FIRST Command in Load/) {
	    $ftt = 0;
	}

    } elsif ($L =~ m/Radmon Disable/) { 
	# Radmon disable
	$nt++;
	$RADMON {$nt}{State} = 0;
	$RADMON {$nt}{Line} = $L;

    } elsif ($L =~ m/Radmon Enable/) { 
	# Radmon enable
	$nt++;
	$RADMON {$nt}{State} = 1;
	$RADMON {$nt}{Line} = $L;

    } elsif ($RADMON {$nt}{State} == 0 && @a > 8 && $a[3] =~ m/^2/ 
	     && $a[5] =~ m/==/) {
	# HRC command during radmon disable.
	# Criteria:
	# At least 10 words in the line
	# Command mnemonic (word 4) starts with 2
	# Word 6 is "=="

	# Anything apart from a format change command is an error
	if (!exists ($okRadmonDis {$a[3]})) {
	    # Note the line and radmon transition number
	    $ne++;
	    $ERR {$ne}{LINE} = $L;
	    $ERR {$ne}{NT} = $nt;
	}
    }
}


if ($ne == 0) {
    print "[OK]  $IP{Prog}\n";
} else {
    print "[FAIL]$IP{Prog} \n";
    print "      Found $ne HRC commands issued after radmon had been disabled:\n";
    for (my $j = 1; $j <= $ne; $j++) {
	print "    Error [$j]\n";
	$nt = $ERR {$j}{NT};
	print "     $RADMON{$nt}{Line}\n";
	print "     $ERR{$j}{LINE}\n";
	$nt++;
	print "     $RADMON{$nt}{Line}\n";
	print "\n";
    }
}

exit ($ne);
