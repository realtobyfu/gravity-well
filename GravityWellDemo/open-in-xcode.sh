#!/bin/bash

# Open the Swift Package in Xcode
# This will allow you to build and run the demo app with Instruments profiling

echo "Opening GravityWellDemo in Xcode..."
echo "NOTE: When Xcode opens:"
echo "  1. Select 'GravityWellDemo' scheme"
echo "  2. Choose an iOS Simulator or connected device"
echo "  3. Build and Run (⌘R) to test the demo"
echo "  4. Profile (⌘I) to open in Instruments for performance analysis"

# Open the package directory in Xcode
open -a Xcode Package.swift