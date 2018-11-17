BUILDS=$(shell egrep -o 'ubuntu/[^ ]*' buildspec.yml | sed -r 's|^ubuntu/||')
NAME=$(shell dirname $@)
VERSION=$(shell basename $@)
TAG=aws/codebuild/$(NAME):$(VERSION)

$(BUILDS):
	cd ubuntu/$(NAME)/$(VERSION) && \
	docker build -t $(TAG) .
