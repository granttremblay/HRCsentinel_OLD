#!/usr/bin/env python

"""Modify an HRC state vector for the impact of an SCS107.
"""

import re
import argparse
from time import gmtime, strftime
import sys


def formatStartTime (startTime):
    """Put start time into a format that can be compared to times in
    the continuity file.
    """
    stmo = re.match (r'(\d{4}:\d{3}:\d{2}:\d{2}:)(\d{2})(\.\d+|\.|)$',
                     startTime)
    if not stmo:
        print "Unexpected start time format:", startTime
        print "Needs to be YYYY:DOY:HH:MM:SS(.S...)"
        sys.exit (1)
    return "{}{:06.3f}".format (stmo.group (1), 
                                float (stmo.group (2) + stmo.group (3)))

        
def mkInitSvrdb (oldsvrdb, startTime):
    """Ouput the headers for the svrdb file and the last line of state
    preceding the SCS107.
    """
    with open (oldsvrdb) as ofh:
        # Copy the header
        for line in ofh:
            if line [0] != '#':
                break
            print line,
        # Line of component names
        print line,
        names = line.split ()
        # Dashes
        line = next (ofh)
        print line,
        ttre = re.compile (r'\d{4}:\d{3}:\d{2}:\d{2}:\d{2}\.\d{3}')
        for line in ofh:
            # Split the time stamp off the front of the line
            ts, b = line.split (None, 1)
            if not ttre.match (ts):
                sys.stderr.write ("Unexpected line format: " + line)
                sys.exit (1)
            if startTime <= ts:
                break
            # print line,
            lastline = line
        print lastline,
        # Final state vector
        vals = lastline.split ()
        if len (names) != len (vals):
            sys.stderr.write ("Names and values not matched: {%d} {%d}\n",
                              len (names), len (vals))
            sys.exit (1)
        return zip (names, vals)


def writeSV (svl, svd):
    """Output state vector values in svrdb order and format.
    svl = original state vector as an ordered list of names and values
    svd = dictionary of updated state vector values
    """
    print "\t".join ([svd [t [0]] for t in svl])


def scs107 (svd):
    """Update the state vector dictionary for the effects of SCS107.
    These are approximate.
    """
    # 1 Radmon disable
    svd ["RADMON"] = "ds"
    # 2 - 7 Nothing
    # 8 Call SCS 108 - move SIM to HRC-S.
    # Although the SCS manual says -99612, the command argument is
    # 20316, which should be 32768 + (SIMTA / 8), agreeing with Jon's
    # value used here.
    svd ["SIMTA"] = "-99616"
    # 9 Call SCS 106 - ACIS safing
    # 10 Call SCS 104 - HRC safing part 1
    #   Terminate SCS 89 (HRC-I ramp up), 90 (HRC-S ramp up), 91 
    #     (HRC dither control)
    svd ["SCS91"] = "term"
    #   Call SCS 87 - HRC-I ramp down
    #   Call SCS 88 - HRC-S ramp down
    #   Disable SCS 89 - HRC-I ramp up
    #   Disable SCS 90 - HRC-S ramp up
    svd ["SCS89"] = "dis"
    svd ["SCS90"] = "dis"
    svd ["HVI"] = "off"
    svd ["HVS"] = "off"
    #   Shield off, voltage step to 0
    svd ["SHLD2PWR"] = "off"
    svd ["SHLD2STEP"] = "0"


############################################################
# Define arguments and help strings
des = "Edit HRC state vector for the impact of SCS107."
parser = argparse.ArgumentParser (description = des)
parser.add_argument ("-s", "--svrdb",
                     help = "input svrdb",
                     default = "/d0/hrc/occ/mp/2015:???????")
parser.add_argument ("-t", "--scs107time", 
                     help = "time of SCS107 (YYYY:DOY:HH:MM:SS.SSS)",
                     default = strftime ("%Y:%j:%H:%M:%S.000", gmtime ()))

# Replan parameters
argdata = parser.parse_args ()
svrdb = argdata.svrdb
tstart = argdata.scs107time

# Reformat for ascii comparision to svrdb file time stamps
tstart = formatStartTime (tstart)

svlist = mkInitSvrdb (svrdb, tstart)
svdict = dict (svlist)

scs107 (svdict)

writeSV (svlist, svdict)
