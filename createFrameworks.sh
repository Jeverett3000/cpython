#! /bin/sh

#  name /Users/holzschu/src/Xcode_iPad/cpython/install/lib/libpython3.9.dylib (offset 24)
#  name @rpath/ios_system.framework/ios_system (offset 24)
#  name /usr/lib/libSystem.B.dylib (offset 24)
#  name /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (offset 24)

for name in python3_ios pythonA pythonB pythonC pythonD pythonE
do 
	framework=${name}
	for architecture in lib.macosx-10.15-x86_64-3.9 lib.darwin-arm64-3.9 lib.darwin-x86_64-3.9
	do
		echo "Creating: " ${architecture}/Frameworks/${name}.framework
		directory=build/${architecture}/Frameworks/
		rm -rf $directory/$framework.framework
		mkdir -p $directory
		mkdir -p $directory/$framework.framework
		libraryFile=build/${architecture}/libpython3.9.dylib
		cp $libraryFile $directory/$framework.framework/$framework
		cp plists/basic_Info.plist $directory/$framework.framework/Info.plist
		plutil -replace CFBundleExecutable -string $framework $directory/$framework.framework/Info.plist
		plutil -replace CFBundleName -string $framework $directory/$framework.framework/Info.plist
		# underscore is not allowed in CFBundleIdentifier:
		signature=${framework//_/-}
		plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$signature  $directory/$framework.framework/Info.plist
		# change framework id:
		install_name_tool -id @rpath/$framework.framework/$framework  $directory/$framework.framework/$framework
	done
	# Edit the Info.plist file:
	plutil -replace DTPlatformName -string "iphoneos" build/lib.darwin-arm64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformName -string "iphonesimulator" build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformName -string "macosx" build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist

	plutil -replace DTSDKName -string "iphoneos" build/lib.darwin-arm64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTSDKName -string "iphonesimulator" build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTSDKName -string "macosx" build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist

	plutil -replace DTPlatformVersion -string "14.0" build/lib.darwin-arm64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformVersion -string "14.0" build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace DTPlatformVersion -string "10.15" build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist

	plutil -replace MinimumOSVersion -string "14.0" build/lib.darwin-arm64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace MinimumOSVersion -string "14.0" build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -replace MinimumOSVersion -string "10.15" build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist

	plutil -replace CFBundleSupportedPlatforms.0 -string "iPhoneSimulator" build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -remove CFBundleSupportedPlatforms.1 build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework/Info.plist

	plutil -replace CFBundleSupportedPlatforms.0 -string "MacOSX" build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist
	plutil -remove CFBundleSupportedPlatforms.1 build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework/Info.plist
# Create the 3-architecture XCFramework:
    rm -rf  XcFrameworks/$framework.xcframework
	xcodebuild -create-xcframework -framework build/lib.macosx-10.15-x86_64-3.9/Frameworks/$framework.framework -framework build/lib.darwin-arm64-3.9/Frameworks/$framework.framework -framework build/lib.darwin-x86_64-3.9/Frameworks/$framework.framework  -output XcFrameworks/$framework.xcframework
	rm -f XcFrameworks/$framework.xcframework.zip
	zip -rq XcFrameworks/$framework.xcframework.zip XcFrameworks/$framework.xcframework
done

# Cleanup install directory from binary files:
find Library -name __pycache__ -exec rm -rf {} \; >& find.log
find Library -name \*.pyc -delete
find Library -name \*.so -delete
find Library -name \*.a -delete
find Library -name \*.dylib -delete
rm -f Library/lib/libpython3.9.dylib
rm -f Library/bin/python3.9
rm -f Library/bin/python3

