#!/usr/bin/perl

#===========================================================================
#
#    J. Chappell (jhc)
#    Copyright:   
#
# 9/23/2016 P Nulsen:
# Checks now made at the end of an HRC observation, so that dither pars
# may be set before or after SCS 91 is activated.
# BUGS FIXED:
# 1) Was using a fixed set of dither parameters instead of those 
#    from the OR.
# 2) Dither params were only checked when dither was enabled.
# 3) If dither was enabled before activating SCS 91, parameters were
#    not checked.
#
# Code from CLP-036-chk_hv_scs_for_selected_detector.pl is superfluous,
# apart from some unnecessary printing.
#
#===========================================================================

use strict;
use warnings;
use checkFotCLP;


our $Version = '$Revision: 1.2 $';
our $Description = 'Check for proper dither parameters for observation.';

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

my $ne   = 0;   # number of errors

# Raw form of the dither parameters
my ($ANGP, $ANGY, $COEFP, $COEFY, $RATEP, $RATEY);
# Dither parameter values
my ($angp, $angy, $coefp, $coefy, $ratep, $ratey);

# Vestige of CLP-036
my %HV;

my $ObsID = -1;
# Science instrument determined from OR info block.  Undefined
# if the OR info block is missing.
my $ObsSI;

# Only SCS 91 is needed
my %SCS;
# Extra parens here quiet deprecation warning
foreach my $scs (qw (87 88 89 90 91 92)) {
    $SCS {$scs}{State} = 0;
    $SCS {$scs}{Line} = "NA";
}

# Indicates searching for dither pars within an HRC OR
my $ditherParSearch = 0;
# HRC OR dither parameters
my ($angpreq, $angyreq, $coefpreq, $coefyreq, $ratepreq, $rateyreq);
# GMT of SCS 91 activation during an HRC observation
# - undef otherwise
my $scs91Time;

# .hrcsel line number
my $nr = -1;
foreach my $L (@HRCSEL){
    $nr++;

    # Remove cr and split on white space
    chomp ($L);
    my @a = split (" ", $L);
    next if @a < 2;

    # Remove redundant white space
    my $L2 = $L;
    $L2 =~ s/\h+/ /g;

    if ($ftt) {
	# Initial state
	if ($L =~ m/DITHER_PAR = /) {
	    # Initial DITHER PARAMETERS
	    my @c = split (':', $a[2]);
	    $ANGP = $c[0];
	    $ANGY = $c[1];
	    $COEFP = $c[2];
	    $COEFY = $c[3];
	    $RATEP = $c[4];
	    $RATEY = $c[5];

	    if ($debug) {
		print "### start of init\n";
		print "  DITHER_PAR:$L\n";
	    }

	    # Initial values are the same
	    $angp = $ANGP;
	    $angy = $ANGY;
	    $coefp = $COEFP;
	    $coefy = $COEFY;
	    $ratep = $RATEP;
	    $ratey = $RATEY;

	} elsif ($L =~ m/HVI = /) {
	    # Initial HRC-I HV state
	    my $det = "I";
	    $HV {$det}{State} = $a[2];
	    $HV {$det}{Line} = "initial state $L";
	    if ($debug) {print "  HV($det):$HV{$det}{Line}\n";}

	} elsif ($L =~ m/HVS = /) {
	    # Initial HRC-S HV state
	    my $det = "S";
	    $HV {$det}{State} = $a[2];
	    $HV {$det}{Line} = "initial state $L";
	    if ($debug) {print "  HV($det):$HV{$det}{Line}\n";}

	} elsif ($L =~ m/SCS87 = /) {
	    # Initial HRC-I ramp down SCS state
	    my $scs = 87;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line}   = "initial state $L";
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS88 = /) {
	    # Initial HRC-S ramp down SCS state
	    my $scs = 88;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS89 = /) {
	    # Initial HRC-I ramp up SCS sate
	    my $scs = 89;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS90 = /) {
	    # Initial HRC-S ramp up SCS state
	    my $scs = 90;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS91 = /) {
	    # Initial HRC dither control SCS state
	    my $scs = 91;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS92 = /) {
	    # Initial HRC-I HV on SCS state
	    my $scs = 92;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";
	    
	    if ($HV {I}{State} =~ /off/) {
		$SCS {$scs}{State} = "term";
	    }
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/SCS93 = /) {
	    # Initial HRC-S HV on SCS state
	    my $scs = 93;
	    $SCS {$scs}{State} = $a[2];
	    $SCS {$scs}{Line} = "initial state $L";

	    if ($HV {S}{State} =~ /off/) {
		$SCS {$scs}{State} = "term";
	    }
	    if ($debug) {print "  SCS($scs):$SCS{$scs}{Line}\n";}

	} elsif ($L =~ m/FIRST Command in Load/) {
	    $ftt = 0;
	    if ($debug) {print "### end of init\n\n";}
	}

    } elsif ($ditherParSearch) {
	# In the OR info for an HRC Obs - get requested dither pars
	if ($L =~ /DITHER = \((.*)\)/) {
	    my $t = $1;
	    my @pcs = split (",", $t);
	    # Parameter order from ObsCat
	    $coefyreq = $pcs [1];
	    $rateyreq = $pcs [2];
	    $angyreq = $pcs [3];
	    $coefpreq = $pcs [4];
	    $ratepreq = $pcs [5];
	    $angpreq = $pcs [6];
	    $ditherParSearch = 0;
	}

    } else {
	if ($L =~ m/^OBSID =/) {
	    # New ObsID 
	    $ObsID = $a[2];
	    $ObsID =~ s/://;
	    if ($debug) {
		print "\n==================================";
		print "\nOBS ID: $ObsID\n";
	    }
	    # Only defined if there is an OR info block
	    $ObsSI = undef;

	} elsif ($L =~ /SI =/) {
	    # Science instrument
	    $ObsSI = $a[2];
	    if ($debug) {print "OBS SI: $ObsSI\n";}
	    # For an HRC observation, start searching for the
	    # requested dither params.
	    # NB: Only get here if OR info is included
	    $ditherParSearch = ($a[2] =~ /HRC/);

	} elsif ($L =~ m/2IMHVOF/) {
	    ### HRC-I HV off 
	    my $det = "I";
	    my $scs = 92;
	    $SCS {$scs}{State} = "term";
	    $HV {$det}{State}  = "off";
	    $HV {$det}{Line}   = $L;
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
		$HV {"I"}{State} = "up";
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
		$HV {"S"}{State} = "up";
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line}  = $L;
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
		$HV {"I"}{State} = "1/2";
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
		$HV {"S"}{State} = "1/2";
	    }
	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HVS ramp down at:$L2\n";}

	} elsif ($L =~ m/SET DITHER PARAMETERS/) {
	    # Read ahead to get dither prameters
	    my $nx = $nr + 1;
	    if ($HRCSEL [$nx] =~ /ANGP =( \d\S+ rad \()(\d\S+) deg\)$/) {
		$angp = $2;
		$ANGP = $1 . $angp . " deg)";
	    } else {
		print "  ANGP not matched: $HRCSEL[$nx]";
	    }

	    $nx++;
	    if ($HRCSEL [$nx] =~ /ANGY =( \d\S+ rad \()(\d\S+) deg\)$/) {
		$angy = $2;
		$ANGY = $1 . $angy . " deg)";
	    } else {
		print "  ANGY not matched: $HRCSEL[$nx]";
	    }

	    $nx++;
	    if ($HRCSEL [$nx] =~ /COEFP =( \d\S+ rad \()(\d\S+) deg\)$/) {
		$coefp = $2;
		$COEFP = $1 . $coefp . " deg)";
	    } else {
		print "  COEFP not matched: $HRCSEL[$nx]";
	    }

	    $nx++;
	    if ($HRCSEL [$nx] =~ /COEFY =( \d\S+ rad \()(\d\S+) deg\)$/) {
		$coefy = $2;
		$COEFY = $1 . $coefy . " deg)";
	    } else {
		print "  COEFY not matched: $HRCSEL[$nx]";
	    }

	    $nx++;
	    if ($HRCSEL [$nx] =~ /RATEP =( \d\S+ rad\/sec \()(\d\S+) deg\/sec\)$/) {
		$ratep = $2;
		$RATEP = $1 . $ratep . " deg/sec)";
	    } else {
		print "  RATEP not matched: $HRCSEL[$nx]";
	    }

	    $nx++;
	    if ($HRCSEL [$nx] =~ /RATEY =( \d\S+ rad\/sec \()(\d\S+) deg\/sec\)$/) {
		$ratey = $2;
		$RATEY = $1 . $ratey . " deg/sec)";
	    } else {
		print "  RATEY not matched: $HRCSEL[$nx]";
	    }

	    if ($debug) {
		print "nr=$nr; L=$L\n"; 
		print "nr=$nr; L=$HRCSEL[$nr]\n"; 
		print "nr=$nr; nr+1; L=$HRCSEL[$nr + 1]\n"; 
		print "Dither Parameters: \n"; 
		print " ANGP  = $ANGP\n";
		print " ANGY  = $ANGY\n";
		print " COEFP = $COEFP\n";
		print " COEFY = $COEFY\n";
		print " RATEP = $RATEP\n";
		print " RATEY = $RATEY\n";
	    }

	} elsif (defined ($scs91Time) && $L =~ /2NXILASL|-> AONMMODE SET PCAD MODE NORMAL MANEUVER/) {
	    # HRC observation is ending - check dither parameters here.
	    # Sanity check
	    if ($SCS {91}{State} !~ m/act/) {
		if (defined ($ObsSI)) {
		    print "  ***WARNING*** End of HRC observation, but SCS91 is $SCS{91}{State} and SI is $ObsSI\n";
		} else {
		    print "  ***WARNING*** End of HRC observation, but SCS91 is $SCS{91}{State} and SI unknown\n";
		}
	    }

	    if (!defined ($ObsSI)) {
		print "  ***WARNING*** No OR info for ObsID $ObsID\n\n";

	    } else {
		print "  Checking Dither parameters:\n";
		if (abs ($angp - $angpreq) < 1e-6) { 
		    print "   angp  ($angp) OK\n"; 
		} else {
		    print "   angp  ($angp) NOT OK\n"; 
		    $ne++;
		}

		if (abs ($angy - $angyreq) < 1e-6) { 
		    print "   angy  ($angy) OK\n"; 
		} else {
		    print "   angy  ($angy) NOT OK\n"; 
		    $ne++;
		}

		if (abs ($coefp - $coefpreq) < 1e-6) { 
		    print "   coefp ($coefp) OK\n"; 
		} else {
		    print "   coefp ($coefp) NOT OK\n"; 
		    $ne++;
		}

		if (abs ($coefy - $coefyreq) < 1e-6) {
		    print "   coefy ($coefy) OK\n"; 
		} else {
		    print "   coefy ($coefy) NOT OK\n"; 
		    $ne++;
		}

		if (abs ($ratep - $ratepreq) < 3e-6) {
		    print "   ratep ($ratep) OK\n"; 
		} else {
		    print "   ratep ($ratep) NOT OK\n"; 
		    $ne++;
		}

		if (abs ($ratey - $rateyreq) < 3e-6) {
		    print "   ratey ($ratey) OK\n\n"; 
		} else {
		    print "   ratep ($ratey) NOT OK\n\n"; 
		    $ne++;
		}
	    }

	    # Flag end of HRC observation
	    $scs91Time = undef;

	} elsif ($L =~ m/DITHER ENABLE/) {
	    ### Check for dither prameters
	    ### print dither states
	    my $scs = 91;
	    print "  scs{$scs} is $SCS{$scs}{State} when ";
	    print "Dither is Enabled @ $a[0] vcdu=$a[2]\n";
	    printf ("  Current Dither Parameters:\n"); 
	    printf ("   ANGP  = %s \n", $ANGP );
	    printf ("   ANGY  = %s \n", $ANGY );
	    printf ("   COEFP = %s \n", $COEFP);
	    printf ("   COEFY = %s \n", $COEFY);
	    printf ("   RATEP = %s \n", $RATEP);
	    printf ("   RATEY = %s \n", $RATEY);
	    printf ("\n");

	    if ($SCS {91}{State} !~ /act/) {
		# The original logic, although what is printed is not
		# strictly correct
		print "  scs91 is NOT active and dither is enabled\n";
	    } elsif (defined ($ObsSI) && $ObsSI !~ /HRC/) {
		print "  scs91 is active, but SI is not HRC and dither is enabled\n";
	    }

	} elsif ($L =~ m/SCS 0x5B/) {
	    ### HRC dither control - scs91
	    my $scs = 91;

	    if ($a[6] =~ m/ENABLE/) {
		$SCS {$scs}{State} = "ena";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/DISABLE/) {
		$SCS {$scs}{State} = "dis";
		$SCS {$scs}{Line} = $L;
	    } elsif ($a[6] =~ m/ACTIVATE/) {
		$SCS {$scs}{State} = "act";
		$SCS {$scs}{Line} = $L;
		$scs91Time = $a[0];
	    } elsif ($a[6] =~ m/TERMINATE/) {
		$SCS {$scs}{State} = "term";
		$SCS {$scs}{Line}  = $L;
	    }

	    if ($debug) {print "SCS $scs $SCS{$scs}{State} HRC Dither control at:$L2\n";}

	    if ($SCS {$scs}{State} =~ m/act/) {
		print "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=\n";
		if (!defined ($ObsSI)) {
		    # Science instrument unknown due to missing OR info
		    print "  OBS: $ObsID\n";

		} else {
		    print "  OBS: $ObsID/$ObsSI\n";

		    ### check for correct state
		    if ($ObsSI =~ m/HRC-S/) {
			# HRC-I states
			my $det = "I"; 
			if ($HV {$det}{State} !~ m/off/) {$ne++; print "ERROR: HV  $det != off\n";}
			
			$scs = 92;
			if ($SCS {$scs}{State}!~ m/term/) {$ne++; print "ERROR: SCS $scs HVI on:  != term\n";}

			$scs = 89;
			if ($SCS {$scs}{State}!~ m/dis/) {$ne++; print "ERROR: SCS $scs HVI ramp up:  != dis\n";}

			$scs = 87;
			if ($SCS{$scs}{State}!~ m/dis/) {$ne++; print "ERROR: SCS $scs HVI ramp down:  != dis\n";}

			# HRC-S states
			$det = "S"; 
			if ($HV {$det}{State} =~ /off/) {
			    $ne++; 
			    print "ERROR:($ObsSI) x $HV{I}{State} x  HV $det == off\n";
			}

			$scs = 93;
			if ($SCS {$scs}{State} !~ m/act/ && $SCS {$scs}{State} !~ m/1\/2/) { 
			    $ne++;
			    print "ERROR: SCS $scs HVS on:  != act|1/2\n"; 
			}

			$scs = 90;
			if ($SCS {$scs}{State} !~ m/ena/) {$ne++; print "ERROR: SCS $scs HVS ramp up:  != ena\n";}

			$scs = 88;
			if ($SCS {$scs}{State} !~ m/ena/ && $SCS{$scs}{State}!~ m/act/) { 
			    $ne++;
			    print "ERROR: SCS $scs HVS ramp down:  != ena|act\n"; 
			}

		    } elsif ($ObsSI =~ m/HRC-I/) {
			# HRC-S states
			my $det = "S"; 
			if ($HV {$det}{State} !~ m/off/) {
			    $ne++; 
			    print "ERROR:($ObsSI) x $HV{I}{State} x  HV $det != off\n"; 
			}

			$scs = 93;
			if ($SCS {$scs}{State} =~ m/act/) {$ne++; print "ERROR: SCS $scs HVS on:  == act\n";}
			
			$scs = 90;
			if ($SCS {$scs}{State} !~ m/dis/) {$ne++; print "ERROR: SCS $scs HVS ramp up:  != dis\n";}

			$scs = 88;
			if ($SCS {$scs}{State} !~ m/dis/) {$ne++; print "ERROR: SCS $scs HVS ramp down:  != dis\n";}

			# HRC-I states
			$det = "I";
			if ($HV {$det}{State} =~ m/off/) {
			    $ne++;
			    print "ERROR:($ObsSI) x $HV{I}{State} x  HV $det == off\n";
			}

			$scs = 92;
			if ($SCS {$scs}{State} !~ m/act/ && $SCS {$scs}{State} !~ m/1\/2/) { 
			    $ne++;
			    print "ERROR: SCS $scs HVI on:  != act|1/2\n"; 
			}

			$scs = 89;
			if ($SCS {$scs}{State} !~ m/ena/) {$ne++; print "ERROR: SCS $scs HVI ramp up:  != ena\n";}

			$scs = 87;
			if ($SCS {$scs}{State} !~ m/ena/ && $SCS {$scs}{State} !~ m/act/) { 
			    $ne++; 
			    print "ERROR: SCS $scs HVI ramp down:  != enai|act\n"; 
			}
		    }
		}

		print "\n";

		@a = split (" ", $L2);
				
		$scs = 91;
		print "  SCS $scs HRC Dither control:  $SCS{$scs}{State} @ $a[0]; vcdu=$a[2]\n"; 

		### print dither states
		printf ("  Dither Parameters:\n"); 
		printf ("   ANGP  = %s \n", $ANGP );
		printf ("   ANGY  = %s \n", $ANGY );
		printf ("   COEFP = %s \n", $COEFP);
		printf ("   COEFY = %s \n", $COEFY);
		printf ("   RATEP = %s \n", $RATEP);
		printf ("   RATEY = %s \n", $RATEY);
		printf("\n");

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
} ### end of read hrcsel loop


if ($ne == 0) {
    print "[OK]   $IP{Prog}\n";

} else {
    print "[FAIL] $IP{Prog}\n";
    print " Found $ne configuration errors:\n";
}


exit ($ne);
