#!/usr/bin/env python
"""Fetch files for a load review.
Replaces CLP_01_GetFotCLP, with a lot less output and greater
flexibility.
"""


import sys
import os
import re
import argparse as ap
import subprocess as sp
import glob


def schedParts (sched, p):
    """Dissect the schedule name to get the date and sequence strings.
    """
    # The schedule name format is:
    # three letter month; two digit date; two digit year; sequence letter
    schmo = re.match (r'([A-Y]{3}[0-3][0-9]{3})([A-Z])\Z', sched)
    if not schmo:
        print "***Incorrect schedule name format:", sched
        p.print_help ()
        sys.exit (1)
                     
    date = schmo.group (1)
    sequence = schmo.group (2)
    
    return date, sequence


############################################################
# Define arguments and help strings
parser = ap.ArgumentParser (description =
                                  "Fetch files needed for a load review.")
parser.add_argument ("scheduleName",
                     help = "load review schedule name")
parser.add_argument ("-dd", "--dataDir",
                     help = "directory where files are downloaded",
                     default = "/d0/hrc/occ/mp/stage")
parser.add_argument ("-f", "--fileHost",
                     help = "name of host with the files",
                     default = "lucky")
parser.add_argument ("-r", "--remoteWD",
                     help = "working directory on remote host",
                     default = "/home/SOT_Transfer")
parser.add_argument ("-t", "--remoteFileTemplate",
                     help = "explicit format for remote file names",
                     default = "{date}/{date}{seq}*.tar.gz")
parser.add_argument ("-x", "--testReview", action = "store_true",
                     help = "use test review format for remote file names")
parser.add_argument ("-p", "--sftpFile",
                     help = "name of sftp command file",
                     default = "X")

args = parser.parse_args ()
date, seq = schedParts (args.scheduleName, parser)
wd = args.dataDir
filehost = args.fileHost
remoteWD = args.remoteWD
fileTemplate = args.remoteFileTemplate
# NB: -x overrides -t
if args.testReview:
    fileTemplate = "{date}{seq}/{date}{seq}*.tar.gz"
remoteFiles = fileTemplate.format (date = date, seq = seq)
sftpFileName = args.sftpFile

# Change to the staging directory
os.chdir (wd)

# Preliminaries as for CLP_01_GetFotCLP
sp.check_call (["ls", "-CFsa"])
ans = raw_input (">> OK to clean out old tar/log files? [Y|n]: ")
if len (ans) and (ans [0] == "n" or ans [0] == "N"):
    sys.stderr.write ("[ERROR] Exit - bye...")
    sys.exit (0)

delFlist = glob.glob ("*.tar.gz")
delFlist.extend (glob.glob ("*log"))
if len (delFlist):
    cmd = ["rm"]
    cmd.extend (delFlist)
    sp.check_call (cmd)

prompt = "{} user name: ".format (filehost)
username = raw_input (prompt)

with open (sftpFileName, "w") as sftpfh:
    sftpfh.write ("cd {}\npwd\nls\nget {}\n".format (remoteWD, remoteFiles))
    sftpfh.close ()
    sp.check_call (["sftp", "-o", "batchmode no", "-b", sftpFileName,
                    "{}@{}".format (username, filehost)])
