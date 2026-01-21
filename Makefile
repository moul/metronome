# Metronome - Cross-platform timing app
# Go CLI + Swift iOS/macOS app

GOPKG ?=	moul.io/metronome
DOCKER_IMAGE ?=	moul/metronome
GOBINS ?=	.
NPM_PACKAGES ?=	.

.PHONY: all build test run clean help swift-build swift-test xcode

## Go CLI (legacy)

all: test install

-include rules.mk

## Swift Package (MetronomeCore)

swift-build:
	cd MetronomeCore && swift build 2>&1 | tee ../build.output

swift-test:
	cd MetronomeCore && swift test 2>&1 | tee ../test.output

## iOS App

run:
	@echo "Opening Xcode... Press Cmd+R to run"
	@if [ -d "Metronome.xcodeproj" ]; then \
		open Metronome.xcodeproj; \
	else \
		echo "No Xcode project found. Create one first."; \
	fi

xcode:
	@if [ -d "Metronome.xcodeproj" ]; then \
		open Metronome.xcodeproj; \
	else \
		echo "No Xcode project found."; \
		echo "Create project: File > New > Project > iOS App"; \
		echo "Then add MetronomeCore as local package dependency."; \
	fi

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
	@echo "Swift targets:"
	@echo "  swift-build  - Build MetronomeCore package"
	@echo "  swift-test   - Run MetronomeCore unit tests"
	@echo "  run          - Open Xcode to run iOS app (Cmd+R)"
	@echo "  xcode        - Open project in Xcode"
	@echo ""
	@echo "General:"
	@echo "  build        - Build all (alias for swift-build)"
	@echo "  test         - Run all tests (alias for swift-test)"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Go CLI (legacy):"
	@echo "  all          - Test and install Go CLI"
