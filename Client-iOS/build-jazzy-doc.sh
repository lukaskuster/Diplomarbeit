#!/bin/bash
# Create Jazzy Documentation Page

jazzy \
	--clean \
	--author Lukas Kuster \
	--author_url https://lukaskuster.com \
	--module SIMplePhoneKit \
	--output ../docs/code-docs/client-ios \
	--theme ../docs/code-docs/source/jazzy-theme
