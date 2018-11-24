BUILDS=$(shell egrep -o 'ubuntu/[^ ]*' buildspec.yml | sed 's|^ubuntu/||')
NAME=$(shell dirname $@)
VERSION=$(shell basename $@)
TAG=aws/codebuild/$(NAME):$(VERSION)

all: $(BUILDS)

$(BUILDS):
	cd ubuntu/$(NAME)/$(VERSION) && \
	docker build -t $(TAG) .
