#!/usr/bin/env python
"""Common code for HRC mission planning checks.  Mimics Jon
Chappel's setup to a large extent.
"""

import sys
import argparse
import os
import glob


def errorExit (rv):
    """Print error info and exit.
    """
    msgfmt = '\n'.join (["Program Error:",
                         " {}",
                         " Program: {}",
                         " Subroutine: {}",
                         " Section: {}",
                         " Error Message: {}"])
    msg = msgfmt.format (rv ["Program"], 
                         rv ["Program"], 
                         rv ["Subroutine"],
                         rv ["Section"], 
                         rv ["ErrorMessage"])
    print msg
    sys.exit (rv ["ReturnValue"])


def getIP (descr, vers):
    """Read parameters from the command line.  Returns the tuple:
    (command line parameter dictionary, return value dictionary)
    """
    parser = argparse.ArgumentParser (description = descr)
    hmsg = "Set the program debug level [0]"
    parser.add_argument ('-d', '--debug', type = int, default = 0, help = hmsg)
    hmsg = "Report the program version [{}]".format (vers)
    parser.add_argument ('--version', action = 'store_true', help = hmsg)
    parser.add_argument ('dd', default = '.', nargs = '?',
                         help = 'Products directory')

    args = parser.parse_args ()
    rv = dict ([("Program", sys.argv [0]),
                ("Subroutine", "getIP"),
                ("Section", ""),
                ("ErrorMessage", ""),
                ("ReturnValue", 0)])
    ip = dict ([("Prog", sys.argv [0]),
                ("CmdLine", " ".join (sys.argv [1:])),
                ("Description", descr),
                ("Version", vers),
                ("DebugLevel", args.debug),
                ("PrintVersion", args.version),
                ("dd", args.dd)])

    if args.debug:
        print "Input parameters:"
        for t in sorted (ip.keys ()):
            print " ", t + ":", ip [t]

    return ip, rv


def validateIP (ip, rv):
    """Handle version print and check that the products directory exists
    and contains an hrcsel file.  Adds the base name of the .hrcsel file
    to the ip dictionary.
    """
    # Return value dictionary
    rv ["Subroutine"] = "validateIP"
    rv ["Section"] = ""
    rv ["ErrorMessage"] = ""
    rv ["RerturnValue"] = 0

    # Check for version print request
    if ip ["PrintVersion"]:
        print ip ["Prog"], ip ["Version"]
        sys.exit (0)

    # Products directory exists?
    dd = ip ["dd"]
    if not os.path.isdir (dd):
        rv ["ErrorMessage"] = "Data directory does not exist [{}]".format (dd)
        rv ["Section"] = "Check for valid data directory."
        rv ["ReturnValue"] = 1
        return rv ["ReturnValue"]

    cwd = os.getcwd ()
    os.chdir (dd)
    c = glob.glob ("*.hrcsel")
    if not c:
        errmsg = "hrcsel file does not exist in dir [{}]\n".format (dd)
        rv ["ErrorMessage"] = errmsg
        rv ["Section"] = "Check for valid data directory files (*.hrcsel)."
        rv ["ReturnValue"] = 1
        return rv ["ReturnValue"]

    # First element of the first file name returned
    ip ["ID"] = c[0].split (".") [0]
    os.chdir (cwd)
    return rv ["ReturnValue"]


def initCheck (descr, vers):
    """Parameter checks prior to reading the .hrcsel file.
    """
    # Read command line
    ip, rv = getIP (descr, vers)
    # Check for a .hrcsel file
    if validateIP (ip, rv):
        errorExit (rv)

    if ip ["DebugLevel"]:
        print "Directory:", ip ["dd"], "\nFile base:", ip ["ID"]

    return ip, rv

