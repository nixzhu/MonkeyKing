#!/usr/bin/env bash

xcodebuild archive -project "China.xcodeproj" \
	-scheme "MonkeyKing" -configuration Release \
	-sdk iphonesimulator \
	-archivePath "build/MonkeyKing/Simulator" \
	SKIP_INSTALL=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive -project "China.xcodeproj" \
	-scheme "MonkeyKing" -configuration Release \
	-sdk iphoneos \
	-archivePath "build/MonkeyKing/iOS" \
	SKIP_INSTALL=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework \
	-framework build/MonkeyKing/Simulator.xcarchive/Products/Library/Frameworks/MonkeyKing.framework \
	-framework build/MonkeyKing/iOS.xcarchive/Products/Library/Frameworks/MonkeyKing.framework \
	-output build/MonkeyKingBinary.xcframework

cd Build && find . -name "*.swiftinterface" -exec sed -i -e 's/MonkeyKing\.MonkeyKing/MonkeyKing/g' {} \;

zip -vry MonkeyKingBinary.xcframework.zip MonkeyKingBinary.xcframework/ -x "*.DS_Store"

echo "\n-----"
swift package compute-checksum MonkeyKingBinary.xcframework.zip
echo "-----"

open .
