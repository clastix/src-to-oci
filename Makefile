include ./utils/misc.Makefile
include ./utils/reqs.Makefile

APP ?= sample
VERSION ?= demo
CLUSTER_REGISTRY := registry:5000
IMAGE ?= $(CLUSTER_REGISTRY)/$(APP):$(VERSION)

.PHONY: reqs
reqs: reqs/cluster reqs/kapp-controller reqs/buildkit/server reqs/registry reqs/buildkit/rbac

.PHONY: app/rbac
app/rbac:
	@$(kubectl) -n default apply -f ./rbac/simpleapp/serviceaccount.yaml
	@$(kubectl) -n default apply -f ./rbac/simpleapp/rolebinding.yaml

.PHONY: app
app: app/rbac
	@$(kubectl) -n default apply -f ./app.yaml
