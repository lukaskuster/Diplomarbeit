#!/bin/bash
# Build Dependacies

#echo "travis_fold:start:Carthage"
#echo "Run Carthage update..."
#./print-time.sh Carthage &
#carthage bootstrap --cache-builds --platform iOS
#pid=$(pgrep -f print-time)
#kill -s KILL $pid
#echo "travis_fold:end:Carthage"

echo "travis_fold:start:WebRTC"
echo "Run WebRTC init..."
./print-time.sh WebRTC &
pid=$(pgrep -f print-time)
mkdir Carthage/
cd Carthage/
mkdir Build/
cd Build/
mkdir iOS/
cd ../../
sh build-webrtc.sh
kill -s KILL $pid
echo "travis_fold:end:WebRTC"
