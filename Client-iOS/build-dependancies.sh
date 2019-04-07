#!/bin/bash
# Build Dependacies

echo "Run Carthage update..."
carthage bootstrap --cache-builds --verbose --platform iOS

echo "Run WebRTC init..."
sh build-webrtc.sh
