"""
Monitor the long-term trending for the HRC 28 volt (main) bus

AUTHOR: Dr. Grant R. Tremblay
        Harvard-Smithsonian Center for Astrophysics


"""
import Chandra.Time
from Ska.engarchive import fetch
from Ska.Matplotlib import plot_cxctime

import time

import matplotlib.pyplot as plt

import numpy as np

from scipy.interpolate import spline

def fetchTelemetry(msid, start, now, filter_bad=True):
    '''
    Fetch the telemetry from the Ska archive for the given MSID.
    filter_bad will call fetch.py's option to automatically filter
    bad data. The stat call should be None, as we don't want daily statistics.

    Returns an instance of class MSID
    '''

    telemetry = fetch.MSID(msid, start, now, filter_bad = filter_bad, stat = 'daily')

    return telemetry

def scaleTelemetry(mainbus_voltage_telemetry, mainbus_current_telemetry):
    """
    Scale the DN values for the 28 volt bus MSIDs
    to an actual voltage/current. I got the list here:
    https://icxc.cfa.harvard.edu/hrcops/msid/hrc.msid.html

    "m" and "b" are coefficients in the formula  V = m * DN + b,
    where V is the voltage being read, DN is the telemetry
    digital value, and b is the offset of the measurement.

    example:  2C15NALV reads digital number 32.

              from the table, m = 0.15625 and b = -20
              the voltage is then V = 0.15625 * 32 + -20 = -15 volts

    MNEMONIC    DESCR            BYTE *     "m"       "b"    value (DN)
    --------  --------           ------    ------    -----   ----------
    2PRBSVL   PRIMARY BUS V *      103     0.3125      -40       217
    2PRBSCR   PRIMARY BUS I *      102     0.0682    -8.65       149
    """

    # THIS IS WRONG!
    # _telemetry.vals IS ALREADY SCALED TO THE CORRECT UNITS!!!

    mainbus_voltage_volts = mainbus_voltage_telemetry.vals
    mainbus_current_amps = mainbus_current_telemetry.vals
    # mainbus_current_amps = 0.0682 * mainbus_current_telemetry.vals + -8.65

    return mainbus_voltage_volts, mainbus_current_amps


def cxctime2plotdate(times):
    """
    Convert input CXC time (sec) to the time base required for the matplotlib
    plot_date function (days since start of year 1).

    :param times: iterable list of times
    :rtype: plot_date times
    """

    # Find the plotdate of first time and use a relative offset from there
    t0 = Chandra.Time.DateTime(times[0]).unix
    plotdate0 = epoch2num(t0)

    return (np.asarray(times) - times[0]) / 86400. + plotdate0



def plotter(times, y, xlim=None, ylim=None, xlabel="Mission Year",
            ylabel="Main Bus Power (W)", title="28 Volt Bus", file="temp.pdf",
            save=False):
    '''Make a pretty plot'''

    # Use a Tufte-approved stylesheet
    plt.style.use('ggplot')

    # Use best-practice labels
    plt.rcParams['font.size'] = 12
    plt.rcParams['axes.labelsize'] = 12
    plt.rcParams['xtick.labelsize'] = 12
    plt.rcParams['ytick.labelsize'] = 12

    pyplot.style.use('ggplot')

    # Use best-practice labels
    pyplot.rcParams['font.size'] = 12
    pyplot.rcParams['axes.labelsize'] = 12
    pyplot.rcParams['xtick.labelsize'] = 12
    pyplot.rcParams['ytick.labelsize'] = 12

    fig, ax = plt.subplots()

    # if fig is None:
    #     fig = pyplot.gcf()
    #
    # if ax is None:
    #     ax = fig.gca()
    #
    # if yerr is not None or xerr is not None:
    #     ax.errorbar(cxctime2plotdate(times), y, yerr=yerr, xerr=xerr, fmt=fmt, **kwargs)
    #     ax.xaxis_date(tz)
    # else:
    #     ax.plot_date(cxctime2plotdate(times), y, fmt=fmt, **kwargs)
    # ticklocs = set_time_ticks(ax)
    # fig.autofmt_xdate()
    #
    # if state_codes is not None:
    #     counts, codes = zip(*state_codes)
    #     ax.yaxis.set_major_locator(FixedLocator(counts))
    #     ax.yaxis.set_major_formatter(FixedFormatter(codes))
    #
    # # If plotting interactively then show the figure and enable interactive resizing
    # if interactive and hasattr(fig, 'show'):
    #     fig.canvas.draw()
    #     ax.callbacks.connect('xlim_changed', remake_ticks)
    #
    # return ticklocs, fig, ax




    fig, ax = plt.subplots()
    plt.plot(x, y)
    fig.show()

def main():

    mainbus_voltage_msid = "2PRBSVL"
    mainbus_voltage_msid = "2P24VAVL"
    mainbus_current_msid = "2PRBSCR"


    missiondays = 6200  # Go back roughly 18 years
    now = Chandra.Time.DateTime().secs
    start = now - missiondays * 24.0 * 3600.0

    mainbus_voltage_telemetry = fetchTelemetry(mainbus_voltage_msid, start, now)
    mainbus_current_telemetry = fetchTelemetry(mainbus_current_msid, start, now)

    mainbus_voltage_volts, mainbus_current_amps = scaleTelemetry(mainbus_voltage_telemetry, mainbus_current_telemetry)

    watts = mainbus_voltage_telemetry.vals * mainbus_current_telemetry.vals

    plot_cxctime(mainbus_voltage_telemetry.times, mainbus_voltage_telemetry.vals, fmt='')
    #plot_cxctime(mainbus_current_telemetry.times, mainbus_current_amps, fmt='')
    #plot_cxctime(mainbus_current_telemetry.times, watts, fmt='')


    #xnew = np.linspace(mainbus_current_telemetry.times.min(),mainbus_current_telemetry.times.max(),300)

    #power_smooth = spline(mainbus_current_telemetry.times,watts,xnew)

    #plot_cxctime(xnew,power_smooth)


    #plotter(times, watts)

if __name__ == '__main__':
    start_time = time.time()
    main()
    runtime = round((time.time() - start_time), 3)
    print("Finished in    |  {} seconds".format(runtime))

    print("Showing plots  |")

    plt.show()
