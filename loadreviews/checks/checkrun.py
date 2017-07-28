#!/usr/bin/env python
"""Run a script and compare its output to expectations.
"""

import sys
import os.path
import subprocess as sp


if len (sys.argv) < 3:
    usestr = "Usage: {} <script> (...) <directory>\n".format (sys.argv [0])
    sys.stderr.write (usestr)
    sys.exit (1)

# Place for output
name = "_".join (sys.argv [1:-1])
name = os.path.basename (name)
if os.path.isdir (sys.argv [-1]):
    subdir = sys.argv [-1]
else:
    name += sys.argv [-1]
    subdir = "testa"
name += ".out"

# print "Running:", " ".join (sys.argv [1:])
process = sp.Popen (sys.argv [1:], stdout = sp.PIPE, stderr = sp.PIPE)
stdout, stderr = process.communicate ()

compare = subdir + "/" + name

if not os.path.isfile (compare):
    print "Writing file:", compare
    with open (compare, "w") as fh:
        fh.write (stderr)
        fh.write (stdout)

else:
    lines = stderr.splitlines ()
    lines.extend (stdout.splitlines ())
    with open (compare) as fh:
        i = 0
        ndiff = 0
        for s in fh:
            if s.rstrip ('\n') != lines [i]:
                ndiff += 1
                print "Difference at", i
                print s
                print lines [i]
            i += 1
    if ndiff == 0:
        print "No differences found"
