SHELL=/bin/bash
ELASTIC_REGISTRY ?= docker.elastic.co
PY_VERSION ?= 3.6.13
export PATH := ./bin:$(HOME)/.pyenv/bin:$(HOME)/.pyenv/shims:./venv/bin:$(PATH)

# Determine the version to build.
ELASTIC_VERSION := $(shell ../vendor/jruby/bin/jruby bin/elastic-version)

ifdef STAGING_BUILD_NUM
  VERSION_TAG := $(ELASTIC_VERSION)-$(STAGING_BUILD_NUM)
else
  VERSION_TAG := $(ELASTIC_VERSION)
endif

ifdef DOCKER_ARCHITECTURE
  ARCHITECTURE := $(DOCKER_ARCHITECTURE)
else
  ARCHITECTURE := $(shell uname -m)
endif

IMAGE_FLAVORS ?= oss full ubi8
DEFAULT_IMAGE_FLAVOR ?= full

IMAGE_TAG := $(ELASTIC_REGISTRY)/logstash/logstash
HTTPD ?= logstash-docker-artifact-server

FIGLET := pyfiglet -w 160 -f puffy

all: build-from-local-artifacts build-from-local-oss-artifacts public-dockerfiles

lint: venv
	flake8 tests

# Build from artifacts on the local filesystem, using an http server (running
# in a container) to provide the artifacts to the Dockerfile.
build-from-local-full-artifacts: venv dockerfile env2yaml
	docker run --rm -d --name=$(HTTPD) \
	           -p 8000:8000 --expose=8000 -v $(ARTIFACTS_DIR):/mnt \
	           python:3 bash -c 'cd /mnt && python3 -m http.server'
	timeout 120 bash -c 'until curl -s localhost:8000 > /dev/null; do sleep 1; done'
	pyfiglet -f puffy -w 160 "Building: full"; \
	docker build --network=host -t $(IMAGE_TAG)-full:$(VERSION_TAG) -f $(ARTIFACTS_DIR)/Dockerfile-full data/logstash || \
	  (docker kill $(HTTPD); false); \
	docker tag $(IMAGE_TAG)-full:$(VERSION_TAG) $(IMAGE_TAG):$(VERSION_TAG);
	docker kill $(HTTPD)

build-from-local-oss-artifacts: venv dockerfile env2yaml
	docker run --rm -d --name=$(HTTPD) \
	           -p 8000:8000 --expose=8000 -v $(ARTIFACTS_DIR):/mnt \
	           python:3 bash -c 'cd /mnt && python3 -m http.server'
	timeout 120 bash -c 'until curl -s localhost:8000 > /dev/null; do sleep 1; done'
	pyfiglet -f puffy -w 160 "Building: oss"; \
	docker build --network=host -t $(IMAGE_TAG)-oss:$(VERSION_TAG) -f $(ARTIFACTS_DIR)/Dockerfile-oss data/logstash || \
	  (docker kill $(HTTPD); false);
	-docker kill $(HTTPD)

build-from-local-ubi8-artifacts: venv dockerfile env2yaml
	docker run --rm -d --name=$(HTTPD) \
	           -p 8000:8000 --expose=8000 -v $(ARTIFACTS_DIR):/mnt \
	           python:3 bash -c 'cd /mnt && python3 -m http.server'
	timeout 120 bash -c 'until curl -s localhost:8000 > /dev/null; do sleep 1; done'
	pyfiglet -f puffy -w 160 "Building: ubi8"; \
	docker build --network=host -t $(IMAGE_TAG)-ubi8:$(VERSION_TAG) -f $(ARTIFACTS_DIR)/Dockerfile-ubi8 data/logstash || \
	  (docker kill $(HTTPD); false);
	-docker kill $(HTTPD)

COPY_FILES = $(ARTIFACTS_DIR)/docker/config/pipelines.yml $(ARTIFACTS_DIR)/docker/config/logstash-oss.yml $(ARTIFACTS_DIR)/docker/config/logstash-full.yml $(ARTIFACTS_DIR)/docker/config/log4j2.properties $(ARTIFACTS_DIR)/docker/pipeline/default.conf $(ARTIFACTS_DIR)/docker/bin/docker-entrypoint $(ARTIFACTS_DIR)/docker/env2yaml/env2yaml

$(ARTIFACTS_DIR)/docker/config/pipelines.yml: data/logstash/config/pipelines.yml
$(ARTIFACTS_DIR)/docker/config/logstash-oss.yml: data/logstash/config/logstash-oss.yml
$(ARTIFACTS_DIR)/docker/config/logstash-full.yml: data/logstash/config/logstash-full.yml
$(ARTIFACTS_DIR)/docker/config/log4j2.properties: data/logstash/config/log4j2.properties
$(ARTIFACTS_DIR)/docker/pipeline/default.conf: data/logstash/pipeline/default.conf
$(ARTIFACTS_DIR)/docker/bin/docker-entrypoint: data/logstash/bin/docker-entrypoint
$(ARTIFACTS_DIR)/docker/env2yaml/env2yaml: data/logstash/env2yaml/env2yaml

$(ARTIFACTS_DIR)/docker/%:
	cp -f $< $@

docker_paths:
	mkdir -p $(ARTIFACTS_DIR)/docker/
	mkdir -p $(ARTIFACTS_DIR)/docker/bin
	mkdir -p $(ARTIFACTS_DIR)/docker/config
	mkdir -p $(ARTIFACTS_DIR)/docker/env2yaml
	mkdir -p $(ARTIFACTS_DIR)/docker/pipeline

public-dockerfiles: public-dockerfiles_oss public_dockerfiles_full public_dockerfiles_ubi8

public-dockerfiles_full: venv templates/Dockerfile.j2 docker_paths $(COPY_FILES)
	jinja2 \
	  -D created_date='$(BUILD_DATE)' \
	  -D elastic_version='$(ELASTIC_VERSION)' \
	  -D arch='${ARCHITECTURE}' \
	  -D version_tag='$(VERSION_TAG)' \
	  -D image_flavor='full' \
	  -D local_artifacts='false' \
	  -D release='$(RELEASE)' \
	  templates/Dockerfile.j2 > $(ARTIFACTS_DIR)/Dockerfile-full && \
	cd $(ARTIFACTS_DIR)/docker && \
	cp $(ARTIFACTS_DIR)/Dockerfile-full Dockerfile && \
	tar -zcf ../logstash-$(VERSION_TAG)-docker-build-context.tar.gz Dockerfile bin config env2yaml pipeline

public-dockerfiles_oss: venv templates/Dockerfile.j2 docker_paths $(COPY_FILES)
	jinja2 \
	  -D created_date='$(BUILD_DATE)' \
	  -D elastic_version='$(ELASTIC_VERSION)' \
	  -D arch='${ARCHITECTURE}' \
	  -D version_tag='$(VERSION_TAG)' \
	  -D image_flavor='oss' \
	  -D local_artifacts='false' \
	  -D release='$(RELEASE)' \
	  templates/Dockerfile.j2 > $(ARTIFACTS_DIR)/Dockerfile-oss && \
	cd $(ARTIFACTS_DIR)/docker && \
	cp $(ARTIFACTS_DIR)/Dockerfile-oss Dockerfile && \
	tar -zcf ../logstash-oss-$(VERSION_TAG)-docker-build-context.tar.gz Dockerfile bin config env2yaml pipeline

public-dockerfiles_ubi8: venv templates/Dockerfile.j2 docker_paths $(COPY_FILES)
	jinja2 \
	  -D created_date='$(BUILD_DATE)' \
	  -D elastic_version='$(ELASTIC_VERSION)' \
	  -D arch='${ARCHITECTURE}' \
	  -D version_tag='$(VERSION_TAG)' \
	  -D image_flavor='ubi8' \
	  -D local_artifacts='false' \
	  -D release='$(RELEASE)' \
	  templates/Dockerfile.j2 > $(ARTIFACTS_DIR)/Dockerfile-ubi8 && \
	cd $(ARTIFACTS_DIR)/docker && \
	cp $(ARTIFACTS_DIR)/Dockerfile-ubi8 Dockerfile && \
	tar -zcf ../logstash-ubi8-$(VERSION_TAG)-docker-build-context.tar.gz Dockerfile bin config env2yaml pipeline

# Push the image to the dedicated push endpoint at "push.docker.elastic.co"
push:
	$(foreach FLAVOR, $(IMAGE_FLAVORS), \
	  docker tag $(IMAGE_TAG)-$(FLAVOR):$(VERSION_TAG) push.$(IMAGE_TAG)-$(FLAVOR):$(VERSION_TAG); \
	  docker push push.$(IMAGE_TAG)-$(FLAVOR):$(VERSION_TAG); \
	  docker rmi push.$(IMAGE_TAG)-$(FLAVOR):$(VERSION_TAG); \
	)
	# Also push the default version, with no suffix like '-oss' or '-full'
	docker tag $(IMAGE_TAG):$(VERSION_TAG) push.$(IMAGE_TAG):$(VERSION_TAG);
	docker push push.$(IMAGE_TAG):$(VERSION_TAG);
	docker rmi push.$(IMAGE_TAG):$(VERSION_TAG);

# The tests are written in Python. Make a virtualenv to handle the dependencies.
venv: requirements.txt
	LOCAL_PY_VER=`python3 --version 2>&1`;\
	echo "Was using $$LOCAL_PY_VER";\
	eval "$$(pyenv init -)" && eval "$$(pyenv init --path)";\
	pyenv install --skip-existing $(PY_VERSION);\
	pyenv local $(PY_VERSION);\
	python3 -mvenv venv; \
	pip install -r requirements.txt;\
	touch venv;\

# Make a Golang container that can compile our env2yaml tool.
golang:
	docker build -t golang:env2yaml data/golang

# Compile "env2yaml", the helper for configuring logstash.yml via environment
# variables.
env2yaml: golang
	docker run --rm -i \
	  -v $(PWD)/data/logstash/env2yaml:/usr/local/src/env2yaml:Z \
	  golang:env2yaml

# Generate the Dockerfiles from Jinja2 templates.
dockerfile: venv templates/Dockerfile.j2
	$(foreach FLAVOR, $(IMAGE_FLAVORS), \
	  jinja2 \
	    -D created_date='$(BUILD_DATE)' \
	    -D elastic_version='$(ELASTIC_VERSION)' \
	    -D arch='${ARCHITECTURE}' \
	    -D version_tag='$(VERSION_TAG)' \
	    -D image_flavor='$(FLAVOR)' \
	    -D local_artifacts='true' \
	    templates/Dockerfile.j2 > $(ARTIFACTS_DIR)/Dockerfile-$(FLAVOR); \
	)

clean:
	rm -f ${ARTIFACTS_DIR}/env2yaml/env2yaml ${ARTIFACTS_DIR}/Dockerfile
	rm -rf venv

.PHONY: clean push
