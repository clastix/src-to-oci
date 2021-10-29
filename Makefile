include ./utils/misc.Makefile
include ./utils/reqs.Makefile

APP ?= sample
VERSION ?= demo
CLUSTER_REGISTRY := registry:5000
IMAGE ?= $(CLUSTER_REGISTRY)/$(APP):$(VERSION)

.PHONY: reqs
reqs: reqs/remote

.PHONY: build
build: reqs
	$(kubectl) buildkit create --config ./config/buildkit/config.toml
	$(kubectl) buildkit build --push -t $(IMAGE) .

.PHONY: template
template:
	@$(ytt) -f ./config

.PHONY: kbld
kbld: reqs
	$(MAKE) -s template | $(kbld) -f -
