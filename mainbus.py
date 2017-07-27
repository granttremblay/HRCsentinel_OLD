#!/usr/bin/env python

"""Monitor the long-term health of the main 28 volt bus
"""

import os
import sys
import argparse

import matplotlib.pyplot as plt
plt.style.use('ggplot')

import Chandra.Time
from Ska.engarchive import fetch

import numpy as np
import re


# Arguments affect imports, so process them early
parser = argparse.ArgumentParser(description='Plot one MSID.')
parser.add_argument('-l', '--lower',
                    help='lower limit: fixed value, prune, or <value>%%')
parser.add_argument('-u', '--upper',
                    help='upper limit: fixed value, prune, or <value>%%')
parser.add_argument('-s', '--slop', type=float,
                    help='slop when pruning outliers, > 1.0', default=2.0)
parser.add_argument('-e', '--expand', type=float,
                    help='scale expansion for pruning or unspecified limit',
                    default=0.03)
parser.add_argument('-d', '--days', type=float,
                    help='number of days to plot', default=6570)
parser.add_argument('-t', '--time',
                    help='end time for plot in Chandra.Time format')
parser.add_argument('-i', '--interact', action='store_true',
                    help='interactive plotting')
parser.add_argument('-p', '--plotfile',
                    help='output plot file when noninteractive')
parser.add_argument('msid', nargs='?',
                    help='MSID to plot')

argdata = parser.parse_args()
if not argdata.msid:
    parser.print_help()
    sys.exit(1)

msid = argdata.msid
lower = argdata.lower
upper = argdata.upper
slop = argdata.slop
expand = argdata.expand
days = argdata.days
endTime = argdata.time
interactive_plot = argdata.interact
plot_dest = argdata.plotfile


def pruneLower(sorted_vals, median, fout, slop):
    """Determine limit to exclude outliers from the low data range.
    Data well outside the percentile defined by fout are excluded.
    """
    n = len(sorted_vals)
    # Maximum number of outliers - might be zero
    nomax = int(fout * n)
    # Minimum lower threshold
    cutval = median - (median - sorted_vals[nomax]) * slop
    if cutval <= sorted_vals[0]:
        return sorted_vals[0]
    ilo = 0
    ihi = nomax
    while ilo + 1 < ihi:
        i = (ilo + ihi) // 2
        if sorted_vals[i] < cutval:
            ilo = i
        else:
            ihi = i
    return sorted_vals[ihi]


def pruneUpper(sorted_vals, median, fout, slop):
    """Determine limit to exclude outliers from the upper data range.
    Data well outside the percentile defined by fout are excluded.
    """
    n = len(sorted_vals)
    # Maximum number of outliers - might be zero
    nomax = int(fout * n)
    # Maximum upper threshold
    ilo = n - 1 - nomax
    cutval = median + (sorted_vals[ilo] - median) * slop
    if sorted_vals[n - 1] <= cutval:
        return sorted_vals[n - 1]
    ihi = n - 1
    while ilo + 1 < ihi:
        i = (ilo + ihi) // 2
        if sorted_vals[i] > cutval:
            ihi = i
        else:
            ilo = i
    return sorted_vals[ilo]


svals = None
median = None


def getLimit(vals, upperlimit, limstring, slop):
    """Numerical value for a lower or upper limit.
    """
    # No lmit string given
    if not limstring:
        # Use data extreme
        if upperlimit:
            return np.amax(vals), True
        else:
            return np.amin(vals), True

    # Prune extreme outliers
    pcprunemo = re.match(r'(.+)%', limstring)
    if pcprunemo:
        fout = 0.01 * float(pcprunemo.group(1))
    else:
        fout = 0.01
    prunemo = re.match(r'prune', limstring)
    if prunemo or pcprunemo:
        global svals, median
        if svals is None:
            svals = np.sort(vals, kind='mergesort')
            n = len(svals)
            # Median
            nh = n // 2
            if n % 2 == 0:
                median = 0.5 * (vals[nh - 1] + vals[nh])
            else:
                median = vals[nh]
        if upperlimit:
            return pruneUpper(svals, median, fout, slop), True
        else:
            return pruneLower(svals, median, fout, slop), True

    # Fixed limit
    return float(limstring), False


def setLimits(vals, lower, upper, slop, expand):
    """Set plot range for y.
    """
    ylow, morelow = getLimit(vals, False, lower, slop)
    yhi, morehi = getLimit(vals, True, upper, slop)
    delta = expand * (yhi - ylow)
    if morelow:
        ylow -= delta
    if morehi:
        yhi += delta
    # Last tweak to prevent the limits from coinciding
    plt.ylim(ylow - 0.001, yhi + 0.001)

def convertDNtoVoltage(m,b):
    """
    Scale the DN values for the 28 volt monitor MSID
    to an actual voltage. I got the list here:
    https://icxc.cfa.harvard.edu/hrcops/msid/hrc.msid.html

    "m" and "b" are coefficients in the formula  V = m * DN + b,
    where V is the voltage being read, DN is the telemetry
    digital value, and b is the offset of the measurement.

    example:  2C15NALV reads digital number 32.

              from the table, m = 0.15625 and b = -20
              the voltage is then V = 0.15625 * 32 + -20 = -15 volts
    """
    pass

if __name__ == '__main__':

    tend = Chandra.Time.DateTime(endTime).secs
    tstart = tend - days * 24.0 * 3600.0

    plt.figure(1)

    dat = fetch.MSID(msid, tstart, tend)
    dat.plot('-r', alpha=0.4)
    plt.title(msid)
    if lower or upper:
        # If either limit is to be set pyplot autoscaling is turned off
        vals = dat.raw_vals if dat.state_codes else dat.vals
        setLimits(vals, lower, upper, slop, expand)

    if plot_dest:
        outfile = plot_dest
    else:
        outfile = msid + '.png'

    if interactive_plot:
        plt.show()
    else:
        plt.savefig(outfile)

    sys.exit()
