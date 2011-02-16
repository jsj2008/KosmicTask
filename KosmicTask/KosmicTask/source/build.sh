
configuration="Release"

# bump it
if [ $configuration = "Release" ] ; then
agvtool bump -all
fi

#build it
xcodebuild -project KosmicTask.xcodeproj -configuration $configuration -target KosmicTask clean build 


