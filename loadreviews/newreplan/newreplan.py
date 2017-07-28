#!/bin/env python
"""Prepare files for a replan, using getloadfiles.py to fetch
the input files.
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
    # Record start time, to check that files are updated
    beforesec = time.time ()
    thisyear = "{} ".format (time.localtime ().tm_year)
    cmd = "getloadfiles.py"
    cmdWD = WDtop + "/stage"
    os.chdir (cmdWD)
    if testReview:
        sp.check_call ([cmd, "-x", "-dd", cmdWD, scName])
        flist = glob.glob (scName + "*.tar.gz")
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
    print "\nFiles downloaded to", cmdWD
    for line in flist:
        print line
    return cmdWD


def unpackFiles (scName, stageWD, reviewWD, contFileName):
    """Unpack the tar files in the review directory and prepare them
    for further processing.  Does steps 0 - 2 of CLP_02_ProcFotCLP.
    Arguments:
    scName = schedule name
    stageWD = staging directory containing the tar files (WD on entry)
    reviewWD = directory for processing load review files
    contFileName = path to continuity file, if specified, or None
    """
    # tar files with load review data
    tarfiles = glob.glob (scName + "*.tar.gz")

    # Set up the review directory
    if not os.path.isdir (reviewWD):
        # Need to create the review directory
        os.mkdir (reviewWD)
        os.chdir (reviewWD)
        print "\nLoad review directory", reviewWD, "created"
    else:
        # Review directory exists, clean it
        os.chdir (reviewWD)
        print "\nLoad review directory", reviewWD, "already exists"
        oldfiles = os.listdir (".")
        if contFileName:
            # A continuity file was specified
            contDir = os.path.dirname (os.path.realpath (contFileName))
            if contDir == os.path.realpath (reviewWD):
                # Continuity file is in the review directory; remove
                # it from the list of files to be deleted
                avoid = os.path.basename (contFileName)
                print "   preserving continuity file", avoid
                oldfiles = [t for t in oldfiles if t != avoid]
        sp.check_call (["rm", "-rf"] + oldfiles)
        print "   cleaned"
    
    # Unpack the tar files
    for f in tarfiles:
        sp.check_call (["tar", "xf", stageWD + "/" + f])

    # Rearrange files
    for fg in ["./mps/or/*.or", "./mps/*.dot"]:
        # Should be a unique file
        f = instanceGlob (fg)
        sp.check_call (["mv", f, "."])

    # Remove unwanted files
    zap = "rm -rf fot History log output mps CL* FOT* m[0-9]* C[0-9]*"
    sp.check_call (zap, shell = True)
    print "\nPrepared load review files:"
    sp.check_call ("ls")


def mkContSvrdb (contName, startTime, p):
    """Set up the continuity state vector file.
    """
    # Locate the continuity file based in its schedule name
    contDirName = schedToDir (contName, p)
    oldsvrdb = "../" + contDirName + "/" + contName + ".svrdb"
    if not (os.path.isfile (oldsvrdb) and os.access (oldsvrdb, os.R_OK)):
        print "***Continuity file", oldsvrdb, "missing or unreadable"
        sys.exit (1)

    print "\nLocated previous state vector database", oldsvrdb

    ttre = re.compile (r'\d{4}:\d{3}:\d{2}:\d{2}:\d{2}\.\d{3}')
    if startTime is None:
        # No edits to svrdb - use the old one in place
        print "Using", oldsvrdb, "as is for continuity"
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
                    print "***No state vectors before", startTime, \
                        "in the continuity file"
                    sys.exit (1)
                fh.close ()
                ofh.close ()
                print "Using edited state vector database", svrdb, \
                    "for continuity"
                return svrdb
            # The time tag precedes startTime
            ngood += 1
        ofh.write (line)
    # Should not happen
    print "***Continuity file has no entries at or after", startTime
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
    print "\nMade", selName


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
continuity = parser.add_mutually_exclusive_group (required = True)
continuity.add_argument ("-c", "--continuitySched", 
                         help = "continuity schedule name")
continuity.add_argument ("-f", "--continuityFile",
                         help = "full path to continuity svrdb")
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
contFile = argdata.continuityFile
startTime = argdata.startTime
unpackWDtop = argdata.workingDir
nocopy = argdata.nocopy
testReview = argdata.testReview

if startTime:
    startTime = checkStartTime (startTime)

# Check schedule format and convert to directory name
scDirName = schedToDir (scName, parser)
loadDir = unpackWDtop + "/" + scDirName


# Fetch load data files into the staging area using getloadfiles.py.
# NB: WD is stageDir after this
stageDir = fetchReplan (scName, unpackWDtop, testReview)


# Unpack the files for processing.
# NB: WD is loadDir after this
unpackFiles (scName, stageDir, loadDir, contFile)


# Create a suitable continuity state vector database.
if contFile:
    # No editing if the file was specified on the command line
    contSvrdb = contFile
    print "\nUsing specified continuity file", contSvrdb
else:
    contSvrdb = mkContSvrdb (contName, startTime, parser)


# Create the new state vector database
newSvrdb =  mkSvrdb (scName, contSvrdb)
print "\nNew state vector database:", newSvrdb

# Extract commands relevant to the HRC
obsReq = instanceGlob ("*.or")
combHrcsel = scName + ".combined.hrcsel"
hrcsel (newSvrdb, obsReq, combHrcsel)


# Format hrcsel file as postscript and copy to HEAD  pool space
fmtNsend (combHrcsel, nocopy)


# Extract vehicle HRC commands
os.chdir ("vehicle")
hrcsel ("../" + newSvrdb, "../" + obsReq, scName + ".vehicle.hrcsel")
