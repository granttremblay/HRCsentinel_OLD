import matplotlib
matplotlib.use ('agg')
import matplotlib.pyplot as plt
import sys
import Chandra.Time
from Ska.engarchive import fetch

#plt.ion()

#start = '2015:050'
#stop = '2015:100'

Now = Chandra.Time.DateTime().secs
start = Now-14.*24.*60.*60.

#msid = '2SMTRATM'
msid = sys.argv[1]

plt.figure(1)
plt.clf()
#dat = fetch.MSID(msid, start, stop, filter_bad = False, stat = None)
dat = fetch.MSID(msid, start, Now, filter_bad = False, stat = None)
dat.plot('-r', alpha=0.4)
plt.title(msid)
#plt.draw()
#plt.show()
outfile = msid + '.png'
plt.savefig(outfile)
#raw_input('{} : press enter to continue '.format(msid))
sys.exit()
