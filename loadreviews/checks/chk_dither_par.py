#!/usr/bin/env python
"""Check that commanded dither parameters match observation requests.
"""

# Mike Juda uses the manouevre file to determine when an HRC observation
# starts, when the dither must be correct.  This script relies solely
# on the .hrcsel file, so it only checks that the dither is correct at the
# end of an HRC observation.

from readyHRCsel import initCheck
import re
import sys


# Dither parameter names.  The values are dither phase (deg),
# amplitude (deg) and frequency (deg/sec)
dpnames = ['ANGP', 'ANGY', 'COEFP', 'COEFY', 'RATEP', 'RATEY']
dpnum = len (dpnames)
badDitherPars = ["0.0", "0.0", "0.0", "0.0", "0.0", "0.0"]

# Tolerances should be determined by significant digits printed.
# Order here matches dpnames
ditParEps = [2e-6, 2e-6, 2e-6, 2e-6, 2e-6, 2e-6]

setDitParRE = re.compile (r'AODITPAR\s+8134401 -> SET DITHER PARAMETERS')
ditherEnableRE = re.compile (r'AOENDITH\s+8034301 -> DITHER ENABLE')
ditherDisableRE = re.compile (r'AODSDITH\s+8034300 -> DITHER DISABLE')
act91s = r'COACTSX\s+8405B00 -> ACTIVATE SCS 0x5B \(91\) HRC Dither Control'
actSCS91RE = re.compile (act91s)
obsidRE = re.compile (r'OBSID = (\d+):')
endObsRE = re.compile (r'-> AONMMODE SET PCAD MODE NORMAL MANEUVER|2NXILASL')


def initialDitherPar (fh):
    """Get dither parameters and state from the initial state vector.
    """
    mre = re.compile (r'Initial Command State Vector:======')
    for t in fh:
        if mre.match (t):
            break

    sv = dict ()

    # Dither on?
    mre = re.compile (r'   DITHER = (\S+)')
    for t in fh:
        mo = mre.match (t)
        if mo:
            s = mo.group (1)
            sv ["dither"] = (s == "en")
            break
    if not "dither" in sv:
        # At EoF without finding dither setting
        print "initialDitherPar: dither setting not found"
        sys.exit (nerr + 1)
        
    # Dither parameters
    mre = re.compile (r'   DITHER_PAR = (\S+)')
    for t in fh:
        mo = mre.match (t)
        if mo:
            s = mo.group (1)
            sv ["ditpar"] = s.split (':')
            break
    if not "ditpar" in sv:
        # At EoF without finding dither pars
        print "initialDitherPar: dither parameters not found"
        sys.exit (nerr + 1)

    # Scan to the end of the introductory comments
    mre = re.compile (r'-> FIRST Command in Load')
    for t in fh:
        if mre.search (t):
            return sv

    # Reached EoF without finding FIRST Command in Load
    print "initialDitherPar: FIRST Command in Load not found"
    sys.exit (nerr + 1)


def trackDitherPar (fh, state):
    """Record satellite dither parameter settings.
    """
    # One dither parameters per line
    newpar = []
    i = 0
    global nerr
    for t in fh:
        pcs = t.split ()
        # Parameter name
        pname = pcs [2]
        # Parameter value
        pval = pcs [6][1:]
        if pname != dpnames [i]:
            print "trackDitherPar: expecting {}, found {}".format (dpnames [i],
                                                                   pname)
            state ["ditpar"] = badDitherPars
            nerr += 1
            return
        newpar.append (pval)
        i += 1
        if i >= dpnum:
            state ["ditpar"] = newpar
            return

    # EoF before end of dither parameters
    print "trackDitherPar: hrcsel file appears to be truncated"
    nerr += 1
    return


def printDitherPar (dp):
    """Formatted print of the list of parameter string values.
    """
    fmt = "{:>8}  {:>12}"
    for i in range (dpnum):
        print fmt.format (dpnames [i], dp [i])
        

def HRCrequest (req, fh):
    """Find requested dither parameters for an HRC observation.
    """
    for t in fh:
        mo = re.match (r'  DITHER = \((\S+)\)', t)
        if mo:
            # From the ObsCat, the order here appears to be:
            # COEFY, RATEY, ANGY, COEFP, RATEP, ANGP.
            # Unshuffle to match setting order.
            dpr = mo.group (1).split (',')[1:]
            req ["ditpar"] = [dpr [5], dpr [2], dpr [3], dpr [0], 
                              dpr [4], dpr [1]]
            return

    # EoF before finding observation dither parameters
    print "HRCrequest: dither parameters not found"
    req ["ditpar"] = badDitherPars
    nerr += 1
    return


def getRequest (fh, mo):
    """Get requested dither parameters.
    """
    req = dict ([("obsid", mo.group (1))])
    for t in fh:
        mo = re.match (r'  SI = (\S+)', t)
        if mo:
            if re.match (r'HRC', mo.group (1)):
                HRCrequest (req, fh)
                if debug:
                    print "Dither requested for HRC ObsID", req ["obsid"]
                    printDitherPar (req ["ditpar"])
                return req
            else:
                # No request for non-HRC observations
                return None

    # EoF before finding science instrument
    print "getRequest: no instrument found"
    nerr += 1
    return None


def checkMatch (req, state):
    """Do the parameters match?
    """
    if req is None:
        print "SCS 91 activated before an HRC request was seen"
        return 1
    rqpars = req ["ditpar"]
    stpars = state ["ditpar"]
    if state ["dither"]:
        # Dither enabled
        myerr = 0
    else:
        myerr = 1
    for i in range (dpnum):
        rqv = float (rqpars [i])
        stv = float (stpars [i])
        if abs (rqv - stv) > ditParEps [i]:
            myerr += 1
    return myerr


def reportBadPar (req, state):
    """Observation has wrong dither parameters.
    """
    print "Bad dither parameters for", req ["obsid"]
    fmt = "{:>8}  {:>12}  {:>12}"
    print fmt.format ("", "configured", "requested")
    rq = req ["ditpar"]
    st = state ["ditpar"]
    for i in range (dpnum):
        print fmt.format (dpnames [i], st [i], rq [i])
    badPars.append ((req ["obsid"], req ["ditpar"], state ["ditpar"]))
    global nerr
    nerr += 1


def scs91Active (fh, req, state):
    """Check that the dither parameters are set as requested for an HRC
    observation.  Scan to the end of observation in case dither parameters
    are set after SCS 91 has been activated.
    """
    # Check settings initially
    mismatch = checkMatch (req, state)
    # Dither pars may be set after SCS 91 is activated, so look for
    # changes up to the end of the observation
    for t in fh:
        if setDitParRE.search (t):
            trackDitherPar (fh, state)
            if debug:
                print "Dither set to:"
                printDitherPar (state ["ditpar"])
            mismatch = checkMatch (req, state)

        elif ditherEnableRE.search (t):
            state ["dither"] = 1
            if debug:
                print "Dither enabled"

        elif ditherDisableRE.search (t):
            state ["dither"] = 0
            if debug:
                print "Dither disabled"

        elif endObsRE.search (t):
            # Parameters need to be good before the end of observation
            if mismatch:
                reportBadPar (req, state)
            elif debug:
                print "Dither matches request for ObsID", req ["obsid"]
            return

    # At EoF - dither should be correct
    if mismatch:
        reportBadPar (req, state)
    elif debug:
        print "Dither parameters OK for", req ["obsid"]
    return



############################################################
# Exit code is number of errors found
nerr = 0

# Process run parameters
description = "Check dither parameters."
version = "$Revision: 1.4 $"
ip, rv = initCheck (description, version)

debug = ip ["DebugLevel"]
badPars = []

# Read through the .hrcsel file
hrcselname = ip ["dd"] + "/" + ip ["ID"] + ".combined.hrcsel"
with open (hrcselname) as hrcselfh:

    # Get initial dither parameters
    hrcstate = initialDitherPar (hrcselfh)
    if debug:
        print "Initial dither parameters:"
        printDitherPar (hrcstate ["ditpar"])

    # No pending HRC observation
    hrcRequest = None

    # Scan the rest of the hrcsel file
    for line in hrcselfh:

        if setDitParRE.search (line):
            # Record commanded dither parameters
            trackDitherPar (hrcselfh, hrcstate)
            if debug:
                print "Dither set to:"
                printDitherPar (hrcstate ["ditpar"])

        elif ditherEnableRE.search (line):
            # Track dither enable
            hrcstate ["dither"] = 1
            if debug:
                print "Dither enabled"

        elif ditherDisableRE.search (line):
            # Track dither enable
            hrcstate ["dither"] = 0
            if debug:
                print "Dither disabled"

        elif actSCS91RE.search (line):
            # SCS 91 is activated at the commencement of an HRC
            # observation.  Finish processing for current request
            scs91Active (hrcselfh, hrcRequest, hrcstate)
            # Done with this HRC observation
            hrcRequest = None

        else:
            # Look for HRC observations
            mo = obsidRE.match (line)
            if mo:
                if hrcRequest:
                    # No new ObsIDs should occur before the current HRC
                    # observation is completed.  Get here if a new ObsID
                    # is encountered before SCS 91 is activated.
                    print "While processing", hrcRequest ["obsid"]
                    print "new ObsID encountered:", mo.group (1)
                    print "  ...confused, but continuing"
                hrcstate ["obsid"] = mo.group (1)
                # Skip engineering ObsID's
                if int (hrcstate ["obsid"]) < 50000:
                    hrcRequest = getRequest (hrcselfh, mo)


# Error report
if nerr:
    print "[FAIL]{}".format (ip ["Prog"])
else:
    print "[OK] ", ip ["Prog"]

sys.exit (nerr)
