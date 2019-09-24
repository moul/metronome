GOPKG ?=	moul.io/metronome
DOCKER_IMAGE ?=	moul/metronome
GOBINS ?=	.
NPM_PACKAGES ?=	.

all: test install

-include rules.mk
