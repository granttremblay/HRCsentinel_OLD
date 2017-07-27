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

def fetchTelemetry(msid, start, now, filter_bad=True):
    '''
    Fetch the telemetry from the Ska archive for the given MSID.
    filter_bad will call fetch.py's option to automatically filter
    bad data. The stat call should be None, as we don't want daily statistics.

    Returns an instance of class MSID
    '''

    telemetry = fetch.MSID(msid, start, now, filter_bad = filter_bad, stat = None)

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

    print mainbus_voltage_telemetry.unit
    return mainbus_voltage_volts, mainbus_current_amps


def plotter(x, y, xlim=None, ylim=None, xlabel="Set your X-label!",
            ylabel="Set your Y-label!", title="Set your Title!", file="temp.pdf",
            save=False):
    '''Make a pretty plot'''

    # Use a Tufte-approved stylesheet
    plt.style.use('ggplot')

    # Use best-practice labels
    plt.rcParams['font.size'] = 12
    plt.rcParams['axes.labelsize'] = 12
    plt.rcParams['xtick.labelsize'] = 12
    plt.rcParams['ytick.labelsize'] = 12

    fig, ax = plt.subplots()
    plt.plot(x, y)
    fig.show()

def main():

    mainbus_voltage_msid = "2PRBSVL"
    mainbus_current_msid = "2PRBSCR"

    missiondays = 6070  # Go back roughly 18 years
    now = Chandra.Time.DateTime().secs
    start = now - missiondays * 24.0 * 3600.0

    mainbus_voltage_telemetry = fetchTelemetry(mainbus_voltage_msid, start, now)
    mainbus_current_telemetry = fetchTelemetry(mainbus_current_msid, start, now)

    mainbus_voltage_volts, mainbus_current_amps = scaleTelemetry(mainbus_voltage_telemetry, mainbus_current_telemetry)

    watts = mainbus_voltage_telemetry.vals * mainbus_current_telemetry.vals

    #plot_cxctime(mainbus_voltage_telemetry.times, mainbus_voltage_telemetry.vals)
    #plot_cxctime(mainbus_current_telemetry.times, mainbus_current_amps)
    plot_cxctime(mainbus_current_telemetry.times, watts)


if __name__ == '__main__':
    start_time = time.time()
    main()
    runtime = round((time.time() - start_time), 3)
    print("Finished in    |  {} seconds".format(runtime))

    print("Showing plots  |")

    plt.show()
