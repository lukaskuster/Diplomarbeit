#!/bin/bash
# Build Dependacies

echo "Run Carthage update..."
while sleep 5m; do echo "=====[ $SECONDS seconds, buildroot still building... ]====="; done &
carthage bootstrap --cache-builds --platform iOS
kill %1

echo "Run WebRTC init..."
while sleep 5m; do echo "=====[ $SECONDS seconds, buildroot still building... ]====="; done &
sh build-webrtc.sh
kill %1
