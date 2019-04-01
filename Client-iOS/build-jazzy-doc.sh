#!/bin/bash
# Create Jazzy Documentation Page

jazzy \
	--clean \
	--author Lukas Kuster \
	--author_url https://lukaskuster.com \
	--module SIMplePhoneKit \
	--output ../Dokumentation/Code-Docs/Client-iOS \
	--theme ../Dokumentation/Code-Docs/source/jazzy-theme
