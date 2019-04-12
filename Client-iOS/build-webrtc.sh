#!/bin/bash
# Build WebRTC.framework
if [ ! -f Carthage/Build/iOS/WebRTC.framework ]; then
    echo "Build WebRTC.framework..."
    mkdir WebRTC
    cd WebRTC

    ## Get Special Google Stuff
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    export PATH=$PATH:$PWD/depot_tools

    ## Fetch WebRTC
    fetch --nohooks webrtc_ios && gclient sync

    ## Build WebRTC
    mkdir release
    cd src
    gn gen ../release -args='target_os="ios" target_cpu="x64" additional_target_cpus=["arm", "arm64", "x86"] is_component_build=false is_debug=false ios_enable_code_signing=false'
    ninja -C ../release framework_objc

    ## Move generated .framework-File and cleanup
    cd ../../
    mv WebRTC/release/WebRTC.framework Carthage/Build/iOS/
fi
