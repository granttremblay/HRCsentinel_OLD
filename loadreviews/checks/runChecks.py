#!/usr/bin/env python
"""Run all CHK scripts and report the sum of the return values.
"""

import sys
import argparse as ap
import glob
import os
import os.path as path
import subprocess as sp


# Command line arguments
helpStr = "Run all checks on the HRC review products."
parser = ap.ArgumentParser (description = helpStr)
parser.add_argument ("DD",
                     help = "directory with review products")
parser.add_argument ("-d", "--debug", type = int, default = 0,
                     help = "debug level")
parser.add_argument ("-s", "--scriptGlob", default = "CHK-0[34][0-9]-*.pl",
                     help = "file glob for check scripts")

args = parser.parse_args ()

scriptName = path.basename (sys.argv [0])
print "===", scriptName, args.DD, "==="
print "Command Line:", ' '.join (sys.argv)
sp.call (["date"])
sp.call (["date", "+%Y:%j:%H:%M:%S"], env = dict (os.environ, TZ = "UTC"))
print "===", scriptName, args.DD, "===\n"

checkScripts = glob.glob (args.scriptGlob)
checkScripts.sort ()

ne = 0
for t in checkScripts:
    cmd = [t]
    if args.debug:
        cmd.extend (["-d", str (args.debug)])
    cmd.append (args.DD)
    print "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
    print " ".join (cmd)
    try:
        output = sp.check_output (cmd)
    except sp.CalledProcessError as cpe:
        output = cpe.output
        ne += cpe.returncode
    print output

print ne, "errors found in load review"

