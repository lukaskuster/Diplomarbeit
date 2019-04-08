#!/bin/bash
# Build Dependacies

carthage_loop=true
echo "travis_fold:start:Carthage"
echo "Run Carthage update..."
./print-time.sh Carthage &
carthage bootstrap --cache-builds --platform iOS
pid=$(pgrep -f print-time)
kill -9 $pid
echo "travis_fold:end:Carthage"

echo "travis_fold:start:WebRTC"
echo "Run WebRTC init..."
./print-time.sh WebRTC &
pid=$(pgrep -f print-time)
sh build-webrtc.sh
kill -9 $pid
echo "travis_fold:end:WebRTC"
