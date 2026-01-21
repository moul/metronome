# Metronome - Cross-platform timing app
# Go CLI + Swift iOS/macOS app

GOPKG ?=	moul.io/metronome
DOCKER_IMAGE ?=	moul/metronome
GOBINS ?=	.
NPM_PACKAGES ?=	.

.PHONY: all build test run clean help swift-build swift-test xcode setup generate

## Go CLI (legacy)

all: test install

-include rules.mk

## Swift Package (MetronomeCore)

swift-build:
	cd MetronomeCore && swift build 2>&1 | tee ../build.output

swift-test:
	cd MetronomeCore && swift test 2>&1 | tee ../test.output

## iOS App

generate:
	@which xcodegen > /dev/null || (echo "Installing xcodegen..." && brew install xcodegen)
	xcodegen generate

run:
	@if [ ! -d "Metronome.xcodeproj" ]; then \
		echo "Generating Xcode project..."; \
		$(MAKE) generate; \
	fi
	open Metronome.xcodeproj

xcode: run

setup:
	@echo ""
	@echo "=== Xcode Project Setup ==="
	@echo ""
	@echo "1. Open Xcode"
	@echo "2. File > New > Project"
	@echo "3. Choose: iOS > App"
	@echo "4. Product Name: Metronome"
	@echo "5. Interface: SwiftUI"
	@echo "6. Language: Swift"
	@echo "7. Save in: $(PWD)"
	@echo ""
	@echo "8. Delete generated ContentView.swift and MetronomeApp.swift"
	@echo "   (we have our own in Metronome/)"
	@echo ""
	@echo "9. Add existing files to project:"
	@echo "   - Drag Metronome/ folder into project navigator"
	@echo "   - Drag MetronomeCore/ folder into project navigator"
	@echo ""
	@echo "10. Add MetronomeCore as package:"
	@echo "    - File > Add Package Dependencies > Add Local"
	@echo "    - Select MetronomeCore folder"
	@echo ""
	@echo "11. Configure bridging header:"
	@echo "    - Build Settings > Objective-C Bridging Header"
	@echo "    - Set to: Metronome/Metronome-Bridging-Header.h"
	@echo ""
	@echo "12. Enable background audio:"
	@echo "    - Target > Signing & Capabilities > + Background Modes"
	@echo "    - Check: Audio, AirPlay, and Picture in Picture"
	@echo ""
	@echo "13. Build and run (Cmd+R)"
	@echo ""

## Build All

build: swift-build
	@echo "Swift package built successfully"

test: swift-test
	@echo "Swift tests completed"

## Cleanup

clean:
	cd MetronomeCore && swift package clean
	rm -rf MetronomeCore/.build
	rm -f *.output

## Help

help:
	@echo "Metronome - Cross-platform timing app"
	@echo ""
	@echo "iOS App:"
	@echo "  run          - Generate project (if needed) and open Xcode"
	@echo "  generate     - Generate Xcode project from project.yml"
	@echo "  xcode        - Alias for run"
	@echo "  setup        - Show manual setup instructions"
	@echo ""
	@echo "Swift Package:"
	@echo "  swift-build  - Build MetronomeCore package"
	@echo "  swift-test   - Run MetronomeCore unit tests"
	@echo ""
	@echo "General:"
	@echo "  build        - Build all (alias for swift-build)"
	@echo "  test         - Run all tests (alias for swift-test)"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Go CLI (legacy):"
	@echo "  all          - Test and install Go CLI"
