#!/usr/bin/env python
"""Check if the eng_archive files have been updated by looking at Tom's
log file.
"""

import re
import sys
import datetime


def checkAppend (fh):
    """Check if data has been added for a representative MSID.
    """
    for line in fh:
        amo = appendRE.match (line)
        if amo:
            print "Appended", amo.group (1), "items for", msid
            sys.exit ()
    print "No data added for", msid


eng_path = "/proj/sot/ska/data/eng_archive"
log_path = "/logs/daily.0"
log_name = "eng_archive.log"
log_file = eng_path + log_path + "/" + log_name

timeStampREstr = r'(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}),\d+ ' \
    r'Run time options:'

hrcStr = "Processing hrc0ss content type"

msid = "2VLEV2RT"
msidrep = "/data/hrc0ss/" + msid
msid_file = eng_path + msidrep
appendREstr = r'.* Appending (\d+) items to ' + msid_file
appendRE = re.compile (appendREstr)

today = datetime.date.today ()
print "Current date: {}-{:02d}-{:02d}".format (today.year, today.month,
                                               today.day)

with open (log_file) as logfh:
    # Is log file date today
    f = logfh.readline ()
    fmo = re.match (timeStampREstr, f)
    if fmo:
        lyear = fmo.group (1)
        lmonth = fmo.group (2)
        lday = fmo.group (3)
        print "Log file date: {}-{}-{}".format (lyear, lmonth, lday)
        iyear = int (lyear)
        imonth = int (lmonth)
        iday = int (lday)
        if iyear != today.year or imonth != today.month or iday != today.day:
            print "Log file date is not today"
            # sys.exit ()

        # Date OK, locate start of HRC entries
        for line in logfh:
            if line.find (hrcStr) != -1:
                # Has any data been added
                checkAppend (logfh)

        print "Failed to find any updates"
