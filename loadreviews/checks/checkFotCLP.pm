package checkFotCLP;

# Code common to the perl test scripts

use strict;
use warnings;
use Exporter;
use Getopt::Long;
use File::Basename;
use Cwd;


our @ISA = qw (Exporter);

# Can be exported
our @EXPORT_OK = qw (GetIP ErrorExit ValidateIP ReadFile vcduCmp inRadiationZone);

# Default exports
our @EXPORT = qw (GetIP ErrorExit ValidateIP ReadFile vcduCmp inRadiationZone);


############################################################
sub GetIP {
    ### Get Input Parameters from the command line (IP)
    #   Input: references to @ARGV;
    #                        hash of Input Parameters (%IP);
    #                        hash of return values (%RV)
    #   Returns: 0 => valid input;  1 => invalid input parameters
    my ($argv, $ip, $rv) = @_;

    # Return Value Structure
    $rv->{Program}      = $0;
    $rv->{Subroutine}   = "GetIP";
    $rv->{Section}      = "";
    $rv->{ErrorMessage} = "";

    # Set default input parameters
    $ip->{Prog}        = $0;
    $ip->{CmdLine}     = "@$argv";

    # Main needs to define these
    $ip->{Description} = $main::Description;
    $ip->{Version} = $main::Version;

    $ip->{PrintVersion}= 0;
    $ip->{DebugLevel}  = 0;
    $ip->{Help}        = 0;

    # Directory containing HRC load products to be checked
    $ip->{dd}           = '.';
    # Used for the load product ID, determined later
    $ip->{ID}           = 'NA';

    ### get the command line options
    if (GetOptions (
	    "version"     => \$ip->{PrintVersion},
	    "d|debug=i"   => \$ip->{DebugLevel},
	    "h|help"      => \$ip->{Help},
	)) {

	# good commandline
	$rv->{ReturnValue} = 0;
	
    } else {
	# bad commandline
	$rv->{Section}      = "GetOptions";
	$rv->{ErrorMessage} = "Error in parsing commandline";
	$rv->{ReturnValue}  = 1;
    }

    if (defined ($argv->[$#$argv])) {
	# Last non-option argument on the command line is the
	# directory containing HRC load products to be checked
	$ip->{dd} = $argv->[$#$argv];
    }

    return $rv->{ReturnValue};
}


############################################################
sub ErrorExit {
    my $rv = $_[0];
    print "Program Error:\n";
    print " $rv->{Program}\n";
    print " Program: $rv->{Program}\n";
    print " Subroutine: $rv->{Subroutine}\n";
    print " Section: $rv->{Section}\n";
    print " Error Message: $rv->{ErrorMessage}\n";
    exit ($rv->{ReturnValue});
}


############################################################
sub PrnUsage
{
    my ($argv, $ip) = @_;

    print "---------------------------------------------------------\n";
    print "$ip->{Prog} ($ip->{Version}):\n  $ip->{Description}\n";
    print "---------------------------------------------------------\n";
    print "usage: $ip->{Prog} [Options] Products_Directory\n";
    print "Options: [defaults in brackets after descriptions]\n";
    print " -d|debug    Set the program debug level [$ip->{DebugLevel}] \n";
    print " -version    Report the program version and exit [$ip->{Version}] \n";
    print " -h|help     Print this message and exit\n";

    return 0;
}


############################################################
sub ValidateIP {
    my ($argv, $ip, $rv) = @_;

    # Checks for version and help print requests.  Checks that the
    # review products directory exists and contains a .hrcsel file.
    # Takes the first element (before the .) of the first .hrcsel file
    # as the product ID.
    # Inputs: references to @ARGV;
    #                       hash of Input Parameters (%IP);
    #                       hash of return values (%RV)
    # Returns: 0 => valid input;  1 => invalid input parameters

    # Return Value Structure
    $rv->{Subroutine}   = "ValidateIP";
    $rv->{Section}      = "";
    $rv->{ErrorMessage} = "";
    $rv->{ReturnValue}  = 0;

    ### Handle a print version request
    if ($ip->{PrintVersion} == 1) {
	print "$ip->{Prog}\t$ip->{Version}\n";
	exit ($rv->{ReturnValue});
    }

    ### Handle a help request
    if ($ip->{Help} == 1 ){
	PrnUsage ($argv, $ip);
	exit ($rv->{ReturnValue});
    }
    
    ### Check data directory exists and get product ID
    if (! -d $ip->{dd}) {
	$rv->{ErrorMessage} = "Data Directory does not exit [$ip->{dd}]\n";
	$rv->{Section}      = "Check for valid data directory.";
	$rv->{ReturnValue}  = 1;
	return $rv->{ReturnValue};

    } else {
	# Look for .hrcsel file in the load products
	my $cwd = getcwd ();
	chdir ($ip->{dd});
	my $cmd  = "ls *.hrcsel > /dev/null";
	my $c = system ($cmd);
	if ($c == 0) {
	    # Any *.hrcsel file allowed here
	    $cmd  = "ls *.hrcsel";
	    my $file = `$cmd`;
	    my @a = split ('\.', $file);
	    # First element of the first *.hrcsel file is taken to be
	    # the product ID
	    $ip->{ID} = $a[0];
	    chdir ($cwd);

	} else {
	    $rv->{ErrorMessage} = "hrcsel file does not exit in dir [$ip->{dd}]\n";
	    $rv->{Section}      = "Check for valid data directory files (*hrcsel).";
	    $rv->{ReturnValue}  = 1;
	    return $rv->{ReturnValue};
	}
    }

    return $rv->{ReturnValue};
}


############################################################
sub ReadFile
{
    # Arguments: file name
    #            array reference
    # The file is read into the referenced array.
    my ($RDBFILE, $hrcsel) = @_;

    open (FD, $RDBFILE) || die "Can't open file: $RDBFILE\n";
    @$hrcsel = <FD>;
    close (FD);
}


############################################################
sub vcduCmp {
    # Difference two VCDU values, allowing for possible rollover.
    # Values to be compared are assumed to be close relative to
    # the maximum VCDU count, so the difference is reduced to the
    # smallest absolute value, modulo the size of the VCDU counter.
    my ($a, $b) = @_;

    # Raw difference
    my $res = $a - $b;

    # VCDU is 24 bits
    my $vcduOverflow = 1 << 24;

    # Smallest absolute value, modulo VCDU length
    if ($res < 0) {
	# By the assumptions, t = a - b + m > 0, while a - b < 0,
	# so |t| < |a - b| => t < b - a => t + a - b < 0
	my $t = $res + $vcduOverflow;
	if ($t + $res < 0) {
	    $res = $t;
	}
    } else {
	# Here, t = a - b - m < 0 and a - b > 0, so |t| < |a - b|
	# => t + a - b > 0
	my $t = $res - $vcduOverflow;
	if ($t + $res > 0) {
	    $res = $t;
	}
    }
    return $res;
}


############################################################
# Does the load start in the radzone?
sub inRadiationZone {
    my ($rHRCSEL, $rl) = @_;

    # Look for the first radzone entry or exit to determine
    # where we are at the start of the load.
    for (my $i = 0; $i < @$rHRCSEL; ++$i) {
	my $t = $rHRCSEL->[$i];
	if ($t =~ /ELECTRON 1 RADIATION (\S+) 0/) {
	    $$rl = $t;
	    if ($1 eq "ENTRY") {
		return 0;
	    } elsif ($1 eq "EXIT") {
		return 1;
	    } else {
		print "BAD LINE, $i: $rHRCSEL->[$i]";
		exit (1);
	    }
	}
    }

    print STDERR "inRadiationBelt: failed to find radiation entry or exit\n";
    exit (1);
}


1;

