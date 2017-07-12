#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Jinja2 prefers the line above (strings default to unicode).
#
# Makes a web page (mostly javascript) to display the daily trend plots.

import os
import re
import time
import argparse
import glob
from jinja2 import Template, Environment, FileSystemLoader


def dirOrder (dir):
    """Convert a directory name of the form path/yyyymmdd to a number
    ordered by date.
    """
    return int (os.path.basename (dir))


def getContents (rawdirs, nthin, nthresh):
    """Of the nonempty plot directories, takes all no older than nthresh
    and one in nthin of the remainder.  It also makes a list of the unique
    lists of plot file sets and a list of keys corresponding to plotdirs 
    to index this list.
    """
    # List of non-empty plot directories
    plotdirs = []
    # List of plot file lists
    pfLists = []
    # Maps from a plot file tuple to the index of the corresponding
    # file list in pfLists
    flDict = dict ()
    # Index in pfLists of the list of plot files in plotdirs [i]
    dirtopfl = []
    nn = 0
    for d in rawdirs:
        # Get the sorted list of plot files in this directory
        dfiles = [os.path.basename (x) for x in glob.glob (d + '/*.png')]
        if len (dfiles):
            if nn <= nthresh or (nn - nthresh) % nthin == 0:
                plotdirs.append (os.path.basename (d))
                dfiles.sort ()
                k = tuple (dfiles)
                if not k in flDict:
                    # Add any new list to the list of plot file lists
                    pfLists.append (dfiles)
                    flDict [k] = len (pfLists) - 1
                # Append the index of this file list to the index list
                dirtopfl.append (flDict [k])
            nn += 1
    return (plotdirs, pfLists, dirtopfl)


def render_trendplots (template_dir, tmpl_file, tmpl_dict):
    """Render the daily trend plot page.
    template_dir = template directory
    tmpl_file = page template file name
    tmpl_dict = dictionary for rendering the template
    """
    # Prepare the web page template.  Installed version of jinja2 on hrc
    # does not understand lstrip_blocks
    page_env = Environment (loader = FileSystemLoader (template_dir),
                            trim_blocks = True)
    templ = page_env.get_template (tmpl_file)
    return templ.render (tmpl_dict)


############################################################
# Defines a simple help command and how to parse arguments
parser = argparse.ArgumentParser (description =
                                  'Make web page of daily trend plots.')
parser.add_argument ('-p', '--plotpath',
                     help = 'path to trend plot directories',
                     default = 'hrctrend')
parser.add_argument ('-c', '--columns', type = int,
                     help = 'number of columns per page', 
                     default = 3)
parser.add_argument ('-t', '--template_file',
                     help = 'plot page template file',
                     default = os.getcwd () + '/trendplot_template.html')
parser.add_argument ('-o', '--output', 
                     help = 'html output file',
                     default = 'dailytrend.html')
parser.add_argument ('-s', '--step', type = int,
                     help = 'thin to every nth directory',
                     default = 1)
parser.add_argument ('-e', '--every', type = int,
                     help = 'only thin older directories',
                     default = 0)

argdata = parser.parse_args ()
plot_path = argdata.plotpath
if plot_path [-1:] != '/':
    plot_path = plot_path + '/'
ncolumn = argdata.columns
template_path = argdata.template_file
destfile = argdata.output
nstep = argdata.step
nall = argdata.every

# Sorted list of plot directories
rawdirs = glob.glob (plot_path + '*')
rawdirs.sort (key = dirOrder, reverse = True)

# plotdirs = thinned list of non-empty plot directories
# filelists = list of unique lists of files in the plot directories
# fileind = list of the index in filelists of the files in each plot directory
plotdirs, filelists, fileind = getContents (rawdirs, nstep, nall)

# Split template file path into directory (assumed to be CWD if empty)
# and file name
tmo = re.match (r'(.*)/(.*)', template_path)
if not tmo:
    template_dir = os.getcwd ()
    template_file = template_path
else:
    template_dir = tmo.group (1)
    template_file = tmo.group (2)

print "plot_path:", plot_path
print "ncolumn:", ncolumn
print "template_dir:", template_dir
print "template_file:", template_file
print "destfile:", destfile
print "plotdirs:", plotdirs
print "filelists:", filelists
print "fileind:", fileind


templ_dict = dict ([('subdirlist', plotdirs),
                    ('plotdirpath', plot_path),
                    ('ncolumn', ncolumn),
                    ('plotfilelists', filelists),
                    ('plotfileind', fileind)])

rendered_html = render_trendplots (template_dir, template_file, templ_dict)
with open (destfile, 'w') as dfh:
    dfh.write (rendered_html)
