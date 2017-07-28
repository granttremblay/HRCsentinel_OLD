#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/30/2016, P Nulsen:
# Common code factored into checkFotCLP and tidied.
#
# Notice missing FIFO reset.
#
# Use vcduCmp() to compute vcdu differences.
#
#===========================================================================

use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Check matched S/C and hrc commanding for format changes.';

my %IP;
my %RV;

### Get/Set the runtime Input Parameters (IP)
ErrorExit (\%RV) if GetIP (\@ARGV, \%IP, \%RV);

### Validate Input Parameters (IP)
ErrorExit (\%RV) if ValidateIP (\@ARGV, \%IP, \%RV);

# read the .hrcsel file
my @HRCSEL;
ReadFile ("$IP{dd}/$IP{ID}.combined.hrcsel", \@HRCSEL);

my %Fmt;
my $nf = 0;   # FIFO reset counter
my $ne = 0;   # FIFO enable counter
my $n = -1;   # Index for CSELFMT commands

foreach my $L (@HRCSEL) {
    my @a = split (" ", $L);

    if ($L =~ m/CSELFMT/) { 
	# Record vcdu and value of spacecraft format command
	$n++;
	$ne = 0;
	$nf = 0;
	$Fmt {$n}{FORMAT_VAL} = $a[7];
	$Fmt {$n}{FORMAT_VCDU} = $a[2];

    } elsif ($L =~ m/2FIFOAOF/) { 
	# Record vcdu of fifo reset cmd
	$Fmt {$n}{$nf++}{FIFORESET_VCDU} = $a[2];

    } elsif ($L =~ m/2FIFOAON/) { 
	# Record vcdu of fifo enable cmd
	$Fmt {$n}{$ne++}{FIFOENABLE_VCDU} = $a[2];

    }
}


my @ERR;
my $rv = 0;
for (my $i = 0; $i <= $n; $i++) {
    # Previously, if $Fmt{$i}{0}{FIFORESET_VCDU} was undefined, no error
    # was reported, allowing the FIFO reset required after a CSELFMT
    # command to be absent.
    my $dvcdu1;
    if (defined ($Fmt {$i}{0}{FIFORESET_VCDU})) {
	$dvcdu1 = vcduCmp ($Fmt {$i}{0}{FIFORESET_VCDU},
			   $Fmt {$i}{FORMAT_VCDU});
    } else {
	$Fmt {$i}{0}{FIFORESET_VCDU} = "no 2FIFOAOF";
	$dvcdu1 = 10000;
    }
    my $dvcdu2;
    if (defined ($Fmt {$i}{0}{FIFOENABLE_VCDU})) {
	$dvcdu2 = vcduCmp ($Fmt {$i}{0}{FIFOENABLE_VCDU},
			   $Fmt {$i}{FORMAT_VCDU});
    } else {
	$Fmt {$i}{0}{FIFOENABLE_VCDU} = "no 2FIFOAON";
	$dvcdu2 = 10000;
    }

    if ($dvcdu1 > 3) {
	$ERR [$rv++] = "fmt_value = $Fmt{$i}{FORMAT_VAL}\n"
	    . "fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}\n"
	    . "fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)\n"
	    . "fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)\n";
    }

    # Raises a second error for the same event
    if ($dvcdu1 > 8) {
	$ERR [$rv++] = "fmt_value = $Fmt{$i}{FORMAT_VAL}\n"
	    . "fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}\n"
	    . "fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)\n"
	    . "fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)\n";
    }

    if ($IP{DebugLevel} > 0) {
	print "$i: =======================================\n";
	print "$i: \n"
	    . "fmt_value = $Fmt{$i}{FORMAT_VAL}\n"
	    . "fmt_vcdu         = $Fmt{$i}{FORMAT_VCDU}\n"
	    . "fifo reset  vcdu = $Fmt{$i}{0}{FIFORESET_VCDU} ($dvcdu1)\n"
	    . "fifo enable vcdu = $Fmt{$i}{0}{FIFOENABLE_VCDU} ($dvcdu2)\n";
	print "\n";
    }
}


if ($rv == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    for (my $i = 0; $i < $rv; $i++) {
	print " $i: $ERR[$i]\n";
	print "\n";
    }
}

exit ($rv);
