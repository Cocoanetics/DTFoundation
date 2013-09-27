#!/bin/sh
set -e

export CURRENT_ARCH=i386
xctool -project DTFoundation.xcodeproj -scheme "Static Library" build test -sdk iphonesimulator
