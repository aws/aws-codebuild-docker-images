BUILDS=$(shell egrep -o 'ubuntu/[^ ]*' buildspec.yml | sed 's|^ubuntu/||')
NAME=$(shell dirname $@)
VERSION=$(shell basename $@)
TAG=aws/codebuild/$(NAME):$(VERSION)

ifdef http_proxy
BLD_OPTS=--build-arg http_proxy=$$http_proxy --build-arg https_proxy=$$https_proxy --build-arg no_proxy=$$no_proxy
endif

all: $(BUILDS)

$(BUILDS):
	cd ubuntu/$(NAME)/$(VERSION) && \
	docker build $(BLD_OPTS) -t $(TAG) .
