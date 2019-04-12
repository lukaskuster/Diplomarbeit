#!/bin/bash
# Build Dependacies

#echo "travis_fold:start:Carthage"
#echo "Run Carthage update..."
#./print-time.sh Carthage &
#pidcarthage=$(pgrep -f print-time)
#carthage bootstrap --cache-builds --platform iOS
#kill -s KILL $pidcarthage
#echo "travis_fold:end:Carthage"

echo "travis_fold:start:WebRTC"
echo "Run WebRTC init..."
pwd
./print-time.sh WebRTC &
pidwebrtc=$(pgrep -f print-time)
mkdir -p Carthage/Build/iOS/
sh build-webrtc.sh
kill -s KILL $pidwebrtc
echo "travis_fold:end:WebRTC"
