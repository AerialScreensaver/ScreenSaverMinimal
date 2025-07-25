#!/bin/sh

BUILD_DATE=$(date "+%Y%m%d_%H%M%S")

# Update Xcode project version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $BUILD_DATE" ${INFOPLIST_FILE}
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_DATE" ${INFOPLIST_FILE}
