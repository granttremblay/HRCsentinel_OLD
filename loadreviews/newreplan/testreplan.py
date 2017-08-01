#!/bin/env python
"""Prepare files for a replan, using getloadfiles.py to fetch
the input files and CLP_02_ProcFotCLP to do the rest.
"""

import re
import time
import sys
import argparse
import subprocess as sp
import os
import glob


def checkStartTime (startTime):
    """Ensure that the start time format is directly comparable 
    to times in the continuity file.
    """
    stmo = re.match (r'(\d{4}:\d{3}:\d{2}:\d{2}:)(.+)', startTime)
    if not stmo:
        print "***Unexpected start time format:", startTime
        print "Needs to be YYYY:DOY:HH:MM:SS(.S...)"
        sys.exit (1)
    return "{}{:06.3f}".format (stmo.group (1), float (stmo.group (2)))
        

def schedToDir (sched, p):
    """Dissect a schedule name to construct a directory name for it.
    """
    # The schedule name format is:
    # three letter month; two digit date; two digit year; sequence letter
    schmo = re.match (r'([A-Y]{3})([0-3][0-9])([0-9]{2})([A-Z])\Z', sched)
    if not schmo:
        print "***Unexpected schedule format:", sched
        p.print_help ()
        sys.exit (1)
                     
    month = schmo.group (1)
    date = schmo.group (2)
    year = schmo.group (3)
    sequence = schmo.group (4)
    # Overkill, but a little more appropriate for Chandra (posix split is 69)
    if int (year) < 90:
        year = "20" + year
    else:
        year = "19" + year

    # Check date is valid and get day of year
    try:
        tmstruct = time.strptime (date + " " + month + " " + year, "%d %b %Y")
    except ValueError:
        print "***Date not recognized in schedule:", sched
        p.print_help ()
        sys.exit (1)
    
    return "{}:{:03d}:{}-{}".format (year, tmstruct.tm_yday, sequence, sched)
    

def instanceGlob (pattern):
    """Translate what should be a unique glob into a file name.
    """
    flist = glob.glob (pattern)
    if len (flist) != 1:
        print "***instanceGlob: glob does not match a single file:", pattern
        sys.exit (1)
    return flist [0]


def fetchReplan (scName, WDtop, testReview):
    """Run getloadfiles.py to collect replan files.  For a standard
    review, also check that the expected files were downloaded.
    """
    beforesec = time.time ()
    thisyear = "{} ".format (time.localtime ().tm_year)
    cmd = "getloadfiles.py"
    cmdWD = WDtop + "/stage"
    os.chdir (cmdWD)
    if testReview:
        sp.check_call ([cmd, "-x", "-dd", cmdWD, scName])
        flist = glob.glob ("*.tar.gz")
    else:
        sp.check_call ([cmd, "-dd", cmdWD, scName])
        # Are all the tar files here?
        fbase = ["backstop", "Commands", "Schedule"]
        flist = [scName + "_" + t + ".tar.gz" for t in fbase]
    flistCmdArgs = ["ls", "-l"] + flist
    flist = sp.check_output (flistCmdArgs).split ('\n') [:-1]
    for line in flist:
        stamp = line.split () [5:8]
        tmf = time.strptime  (thisyear + " ".join (stamp), "%Y %b %d %H:%M")
        ftime = time.mktime (tmf)
        # Seconds omitted from time stamps
        if ftime + 60.0 < beforesec:
            print "***Old file:", line
            sys.exit (1)
    return cmdWD


def unpackFiles (scName, WDtop, getWD):
    """Unpack the tar files in the appropriate directory for further
    processing.
    """
    # Use Jon's stage arguments to skip the useless steps
    unpackCmd = "CLP_02_ProcFotCLP"
    unpackCmdArgs = [unpackCmd, "-id", getWD, "-od", WDtop, "-ps", "0-2", 
                     scName]
    # Jon's script checks for the files, even though the processing
    # steps to make them are skipped
    try:
        sp.check_call (unpackCmdArgs)
    except sp.CalledProcessError:
        print 'The message "ERROR: vehicle/ does not exist" is expected above.'
        print "Any other error message may be significant."


def mkContSvrdb (loadDir, contDirName, contName, startTime):
    """Set up the continuity state vector file.
    """
    #    loadDir = unpackWDtop + "/" + scDirName
    os.chdir (loadDir)

    oldsvrdb = "../" + contDirName + "/" + contName + ".svrdb"
    if not (os.path.isfile (oldsvrdb) and os.access (oldsvrdb, os.R_OK)):
        print "***Continuity file", oldsvrdb, "missing or unreadable"
        sys.exit (1)

    ttre = re.compile (r'\d{4}:\d{3}:\d{2}:\d{2}:\d{2}\.\d{3}')
    if startTime is None:
        # No edits to svrdb - use the old one in place
        return oldsvrdb

    # Copy the desired entries to make the edited continuity file
    svrdb = contName + ".svrdb.cont"
    fh = open (oldsvrdb, "r")
    ofh = open (svrdb, "w")
    ngood = 0
    for line in fh:
        # Check time stamps
        ts, b = line.split (None, 1)
        if ttre.match (ts):
            # Line has a time stamp
            if startTime <= ts:
                # Omit all entries after the start time
                if ngood == 0:
                    print "***No state vector entries later than", startTime, \
                        "in the continuity file"
                    sys.exit (1)
                fh.close ()
                ofh.close ()
                return svrdb
            # The time tag precedes startTime
            ngood += 1
        ofh.write (line)
    # Should not happen
    print "***Continuity file has no entries later than", startTime
    print "***If that is intentional, omit the -s option."
    sys.exit (1)


def mkSvrdb (scName, contSvrdb):
    """Make a new state vector database for the load.
    """
    mksvrdbCmd = "bs2svrdb"
    bsFile = instanceGlob ("*.backstop")
    mksvrdbArgs = [mksvrdbCmd, "-s", contSvrdb, "-b", bsFile]
    newSvrdb = scName + ".svrdb"
    svrdbfh = open (newSvrdb, "w")
    sp.check_call (mksvrdbArgs, stdout = svrdbfh)
    svrdbfh.close ()
    return newSvrdb


def hrcsel (svrdb, obsreq, selName):
    """Extract commands relevant to the HRC.
    """
    hrcCmd = "fotclp2hrcclp"
    tlrfile = instanceGlob ("*.tlr")
    bsfile = instanceGlob ("*.backstop")
    hrcArgs = [hrcCmd, "-s", svrdb, "-o", obsreq, "-t", tlrfile, "-b", bsfile]
    selfh = open (selName, "w")
    sp.check_call (hrcArgs, stdout = selfh)
    selfh.close ()


def fmtNsend (sel, nocpy):
    """Pretty print the file of selected HRC commands and scp them to
    pool space.
    """
    fmtCmd = "enscript"
    psFile = sel + ".ps"
    sp.check_call ([fmtCmd, "-f", "Courier6", "-r", "-o", psFile, sel])
    if not nocopy:
        destdir = "/pool7/hrc/"
        desthost = "hrc@quango.cfa.harvard.edu:"
        sp.check_call (["scp", sel, psFile, desthost + destdir])


############################################################
# Define arguments and help strings
parser = argparse.ArgumentParser (description =
                                  "Generate load review products for a replan.")
parser.add_argument ("scheduleName",
                     help = "replan schedule name")
parser.add_argument ("-c", "--continuitySched", 
                     required = True,
                     help = "continuity schedule name")
parser.add_argument ("-s", "--startTime", 
                     help = "schedule start time (YYYY:DOY:HH:MM:SS.SSS)")
parser.add_argument ("-w", "--workingDir",
                     help = "top level working directory",
                     default = "/d0/hrc/occ/mp")
parser.add_argument ("-n", "--nocopy", action = 'store_true',
                     help = "omit copy to /pool7",
                     default = False)
parser.add_argument ("-x", "--testReview", action = "store_true",
                     help = "review files location as for test review")

# Replan parameters
argdata = parser.parse_args ()
scName = argdata.scheduleName
contName = argdata.continuitySched
startTime = argdata.startTime
unpackWDtop = argdata.workingDir
nocopy = argdata.nocopy
testReview = argdata.testReview

if not startTime is None:
    startTime = checkStartTime (startTime)


# Check schedule formats and convert to directory names
scDirName = schedToDir (scName, parser)
contDirName = schedToDir (contName, parser)


# Fetch load data files into the staging area using getloadfiles.py script.
# NB: in the staging directory after this
getCmdWD = fetchReplan (scName, unpackWDtop, testReview)


# Unpack the files for processing using Jon's script
unpackFiles (scName, unpackWDtop, getCmdWD)


# Create a suitable continuity state vector database.
# NB: in loadDir after this
loadDir = unpackWDtop + "/" + scDirName
contSvrdb = mkContSvrdb (loadDir, contDirName, contName, startTime)


# Create the new state vector database
newSvrdb =  mkSvrdb (scName, contSvrdb)


# Extract the HRC commands
obsReq = instanceGlob ("*.or")
combHrcsel = scName + ".combined.hrcsel"
hrcsel (newSvrdb, obsReq, combHrcsel)


# Format hrcsel file as postscript and copy to HEAD  pool space
fmtNsend (combHrcsel, nocopy)


# Extract vehicle HRC commands
os.chdir ("vehicle")
hrcsel ("../" + newSvrdb, "../" + obsReq, scName + ".vehicle.hrcsel")
