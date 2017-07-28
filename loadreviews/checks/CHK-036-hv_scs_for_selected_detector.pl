#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 8/30/2016, P Nulsen:
# Factored common code into checkFotCLP and tidied.
#
#===========================================================================


use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 2.0 $';
our $Description = 'Check hv scs for selected detector.';

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
my $ftt = 1;   # first time thru flag
my $ne = 0;   # number of errors

my %HV;

my %PREAMPA;
my %RADMON;
$RADMON {State} = -1;

my %OBS;
$OBS {ID} = -1;
$OBS {SI} = "NA" ;

my %SCS;

foreach my $L (@HRCSEL) {
    # remove the cr and split the line on white spaces
    chomp($L);
    my @a = split (" ", $L);
    next if @a < 2;

    # Compress horizontal space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    if ($ftt) {
	# Get initial HV and SCS states
	if ($L =~ m/RADMON = /) {
	    # RADMON tracked, but only used for debug output
	    if ($a[2] =~ m/ds/) {
		$RADMON {State}  = 0;
	    } else {
		$RADMON {State}  = 1;
	    }
	    $RADMON {Line} = "initial state $L";
	    if ($debug) {
		print "### start of init\n";
		print "  RADMON:$RADMON{Line}: ($RADMON{State})\n";
	    }

	} elsif ($L =~ m/PREAMPA = /) {
	    # Retained only to keep output identical
	    $PREAMPA {State} = $a[2];
	    $PREAMPA {Line} = "initial state $L";
	    if ($debug) {print "  PREAMPA:$PREAMPA{Line}\n";}

	} elsif ($L =~ m/HVI = /) {
	    my $det = "I";
	    $HV {$det}{State} = $a[2];
	    $HV {$det}{Line} = "initial state $L";
	    if ($debug) {print "  HV($det):$HV{$det}{Line}\n";}

	} elsif ($L =~ m/HVS = /) {
	    my $det = "S";
	    $HV {$det}{State} = $a[2];
	    $HV {$det}{Line} = "initial state $L";
	    if ($debug) { print "  HV($det):$HV{$det}{Line}\n"; }

	} elsif ($L =~ m/SCS(\d{2}) = /) {
	    my $scs = $1;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    # SCS92 and SCS93 are only ever activated in a load,
	    if ($scs == 92) {
		if ($HV {I}{State} =~ /off/) {
		    $SCS {$scs}{State} = "term";
		}
	    } elsif ($scs == 93) {
		if ($HV {S}{State} =~ /off/) {
		    $SCS{$scs}{State} = "term";
		}
	    }
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	}elsif ($L =~ m/FIRST Command in Load/) {
	    $ftt = 0;
	    if ($debug) {print "### end of init\n\n";}

	}

    } else {
	if ($L =~ m/^OBSID =/) {
	    ### ObsID 
	    $OBS {ID} = $a[2];
	    $OBS {ID} =~ s/://;
	    if ($debug) {
		print "\n==================================";
		print "\nOBS ID: $OBS{ID}\n";
	    }

	} elsif ($L =~ m/SI =/) {
	    ### OBS SI 
	    $OBS {SI} = $a[2];
	    if ($debug) {print "OBS SI: $OBS{SI}\n";}

	} elsif ($L =~ m/Radmon Enable/) {
	    ### Radmon Enable 
	    $RADMON {State} = 1;
	    $RADMON {Line} = $L;
	    if ($debug) {print "RADMON $RADMON{State}  at:$L2\n";}

	} elsif ($L =~ m/Radmon Disable/) {
	    ### Radmon Disable 
	    $RADMON {State} = 0;
	    $RADMON {Line} = $L;
	    if ($debug) {print "RADMON $RADMON{State}  at:$L2\n";}

	} elsif ($L =~ m/2IMHVOF/) {
	    ### HRC-I HV off 
	    my $det = "I";
	    my $scs = 92;
	    $SCS {$scs}{State} = "term";
	    $HV {$det}{State} = "off";
	    $HV {$det}{Line} = $L;
	    if ($debug) {print "HV $det $HV{$det}{State}  at:$L2\n";}

	} elsif ($L =~ m/2SPHVOF/) {
	    ### HRC-S HV off 
	    my $det = "S";
	    my $scs = 93;
	    $SCS {$scs}{State} = "term";
	    $HV {$det}{State} = "off";
	    $HV {$det}{Line} = $L;
	    if ($debug) {print "HV $det $HV{$det}{State}  at:$L2\n";}

	} elsif ($L =~ m/ACTIVATE SCS 0x5C \(92\) HRC-I HV On/) {
	    ### HRC-I HV on - scs92
	    my $scs = 92;
	    my $det = "I";
	    $HV {$det}{State} = "on";
	    $SCS {$scs}{State} = "act";
	    $SCS {$scs}{Line} = $L;
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVI on at:$L2\n";}

	} elsif ($L =~ m/ACTIVATE SCS 0x5D \(93\) HRC-S HV On/) {
	    ### HRC-S HV on - scs93
	    my $scs = 93;
	    my $det = "S";
	    $HV {$det}{State} = "on";
	    $SCS {$scs}{State} = "act";
	    $SCS {$scs}{Line} = $L;
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVS on at:$L2\n";}

	} elsif ($L =~ m/SCS 0x59 \(89\) HRC-I HV Ramp Up/) {
	    ### HRC-I HV ramp up - scs89
	    my $scs = 89;
	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
		my $det = "I";
		$HV {$det}{State} = "up";
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line} = $L;
	    }
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVI ramp up at:$L2\n";}

	} elsif ($L =~ m/SCS 0x5A \(90\) HRC-S HV Ramp Up/) {
	    ### HRC-S HV ramp up  - scs90
	    my $scs = 90;
	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
		my $det = "S";
		$HV {$det}{State} = "up";
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line} = $L;
	    }
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVS ramp up at:$L2\n";}

	} elsif ($L =~ m/SCS 0x57 \(87\) HRC-I HV Ramp Down/) {
	    ### HRC-I HV ramp down - scs87
	    my $scs = 87;
	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/ACTIVATE/) {
		$SCS {$scs}{State} = "act";
		$SCS {$scs}{Line} = $L;
		my $det = "I";
		$HV {$det}{State} = "1/2";
	    }
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVI ramp down at:$L2\n";}

	} elsif ($L =~ m/SCS 0x58 \(88\) HRC-S HV Ramp Down/) {
	    ### HRC-S HV ramp down  - scs88
	    my $scs = 88;
	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/ACTIVATE/) {
		$SCS {$scs}{State} = "act";
		$SCS {$scs}{Line} = $L;
		my $det = "S";
		$HV {$det}{State} = "1/2";
	    }
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVS ramp down at:$L2\n";}

	} elsif ($L =~ m/SCS 0x5B/) {
	    ### HRC dither control - scs91
	    my $scs = 91;
	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line}  = $L;
	    } elsif ($a[6] =~ m/ACTIVATE/) {
		$SCS {$scs}{State} = "act";
		$SCS {$scs}{Line}  = $L;
	    } elsif ($a[6] =~ m/TERMINATE/) {
		$SCS {$scs}{State} = "term";
		$SCS {$scs}{Line}  = $L;
	    }
	    if ($debug) {
		print "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n";
	    }

	    if ($SCS {$scs}{State} =~ m/act/) {
		# Checks are run when HRC dither control is activated
		print "==================================================\n";
		print "  OBS: $OBS{ID}/$OBS{SI}\n";

		### Check HV state
		if ($OBS {SI} =~ m/HRC-S/) {
		    # HRC-I states
		    my $det = "I"; 
		    if ($HV {$det}{State} !~ m/off/) {
			$ne++; 
			print "ERROR: HV  $det != off\n";
		    }
		    $scs = 92;
		    if ($SCS {$scs}{State} !~ m/term/) {
			$ne++; 
			print "ERROR: SCS $scs HVI on:  != term\n";
		    }
		    $scs = 89;
		    if ($SCS {$scs}{State} !~ m/dis/) {
			$ne++; 
			print "ERROR: SCS $scs HVI ramp up:  != dis\n";
		    }
		    $scs = 87;
		    if ($SCS {$scs}{State} !~ m/dis/) {
			$ne++; 
			print "ERROR: SCS $scs HVI ramp down:  != dis\n"; 
		    }

		    # HRC-S states
		    $det = "S"; 
		    if ($HV {$det}{State} =~ /off/) {
			$ne++; 
			print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det == off\n"; 
		    }
		    $scs = 93;
		    if ($SCS {$scs}{State} !~ m/act/) {
			$ne++;
			print "ERROR: SCS $scs HVS on:  != act|1/2\n"; 
		    }
		    $scs = 90;
		    if ($SCS {$scs}{State} !~ m/ena/) {
			$ne++; 
			print "ERROR: SCS $scs HVS ramp up:  != ena\n";
		    }
		    $scs = 88;
		    if ($SCS {$scs}{State} !~ m/ena/
			&& $SCS{$scs}{State}!~ m/act/) { 
			$ne++;
			print "ERROR: SCS $scs HVS ramp down:  != ena|act\n"; 
		    }
		}
		
		if ($OBS {SI} =~ m/HRC-I/) {
		    # HRC-S states
		    my $det = "S"; 
		    if ($HV {$det}{State} !~ m/off/) {
			$ne++; 
			print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det != off\n"; 
		    }
		    $scs = 93;
		    if ($SCS {$scs}{State} =~ m/act/) {
			$ne++;
			print "ERROR: SCS $scs HVS on:  == act\n";
		    }
		    $scs = 90;
		    if ($SCS {$scs}{State} !~ m/dis/) {
			$ne++; 
			print "ERROR: SCS $scs HVS ramp up:  != dis\n";
		    }
		    $scs = 88;
		    if ($SCS {$scs}{State} !~ m/dis/) {
			$ne++;
			print "ERROR: SCS $scs HVS ramp down:  != dis\n"; 
		    }

		    # HRC-I states
		    $det = "I";
		    if ($HV {$det}{State} =~ m/off/) {
			$ne++;
			print "ERROR:($OBS{SI}) x $HV{I}{State} x  HV $det == off\n";
		    }
		    $scs = 92;
		    if ($SCS{$scs}{State} !~ m/act/) {
			$ne++;
			print "ERROR: SCS $scs HVI on:  != act|1/2\n"; 
		    }
		    $scs = 89;
		    if ($SCS {$scs}{State} !~ m/ena/) {
			$ne++;
			print "ERROR: SCS $scs HVI ramp up:  != ena\n";
		    }
		    $scs = 87;
		    if ($SCS {$scs}{State} !~ m/ena/
			&& $SCS{$scs}{State}  !~ m/act/) { 
			$ne++;
			print "ERROR: SCS $scs HVI ramp down:  != enai|act\n"; 
		    }
		}

		print "\n";

		$scs = 91;
		print "  SCS $scs HRC Dither control:  $SCS{$scs}{State} @ $a[0]; vcdu=$a[2]\n"; 
		print "\n";

		my $det = "S";
		print "  HV $det:  $HV{$det}{State}\n";

		### HRC-S HV on - scs93
		$scs = 93;
		print "  SCS $scs HVS on:  $SCS{$scs}{State}\n"; 

		### HRC-S HV ramp up  - scs90
		$scs = 90;
		print "  SCS $scs HVS ramp up: $SCS{$scs}{State}\n"; 

		### HRC-S HV ramp down  - scs88
		$scs = 88;
		print "  SCS $scs HVS ramp down: $SCS{$scs}{State}\n"; 

		print "\n";
		
		$det = "I";
		print "  HV $det:  $HV{$det}{State}\n";

		### HRC-I HV on - scs92
		$scs = 92;
		print "  SCS $scs HVI on: $SCS{$scs}{State}\n";

		### HRC-I HV ramp up - scs89
		$scs = 89;
		print "  SCS $scs HVI ramp up: $SCS{$scs}{State}\n"; 

		### HRC-I HV ramp down - scs87
		$scs = 87;
		print "  SCS $scs HVI ramp down: $SCS{$scs}{State}\n"; 

		print "\n";
	    }
	}
    }
}


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";
} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
}

exit ($ne);
