#!/bin/sh
set -e

#xctool -project DTFoundation.xcodeproj -scheme "Static Library" build test -sdk iphonesimulator -arch i386 ONLY_ACTIVE_ARCH=NO
xctool -project DTFoundation.xcodeproj -scheme "Static Library" build test -sdk iphonesimulator -arch i386 CURRENT_ARCH=i386
