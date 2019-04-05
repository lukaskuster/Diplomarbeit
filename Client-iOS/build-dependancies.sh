#!/bin/bash
# Build Dependacies

echo "Run Carthage update..."
carthage update --cache-builds --no-use-binaries --platform iOS

echo "Run WebRTC init..."
sh build-webrtc.sh
