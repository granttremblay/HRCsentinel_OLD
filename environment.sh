#!/bin/sh

SKA=/home/grant/Engineering/sot/ska;
export SKA;

echo "Ska environment defined: $SKA"

py2
echo "Ensuring you're using Python 2.X:"
which python

echo "Done"
