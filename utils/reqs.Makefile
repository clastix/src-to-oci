kind 			:= $(shell command -v kind 2> /dev/null)
ytt 			:= $(shell command -v ytt 2> /dev/null)
kbld 			:= $(shell command -v kbld 2> /dev/null)
kapp 			:= $(shell command -v kapp 2> /dev/null)
kubectl 	:= $(shell command -v kubectl 2> /dev/null)
#buildkit_cli_url ?= https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/v0.1.4/darwin-v0.1.4.tgz
buildkit_cli_url ?= https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/v0.1.4/linux-v0.1.4.tgz

# Cluster run requirements

.PHONY: reqs/remote
reqs/remote: reqs/cluster reqs/kapp-controller reqs/cluster-registry

.PHONY: reqs/local
reqs/local: reqs/cluster reqs/buildkit-for-kubectl reqs/cluster-registry

.PHONY: reqs/cluster
reqs/cluster: kind

.PHONY: reqs/kapp-controller
reqs/kapp-controller: reqs/kapp
	@$(kapp) deploy -y -a kc -f ./kapp-controller

.PHONY: reqs/buildkit/server
reqs/buildkit/server: reqs/buildkit/client
	@$(kubectl) buildkit -n kapp-controller create --config ./buildkit/config.toml
	@$(kubectl) -n kapp-controller create configmap buildkit \
		--from-file=./buildkit/config.toml --dry-run=client -o yaml \
		| $(kubectl) apply -f -

.PHONY: reqs/buildkit/rbac
reqs/buildkit/rbac:
	@$(kubectl) -n kapp-controller apply -f ./rbac/kubectl-buildkit/clusterrole.yaml
	@$(kubectl) -n kapp-controller apply -f ./rbac/kubectl-buildkit/rolebinding.yaml

# Local run requirements

.PHONY: reqs/buildkit/client
reqs/buildkit/client:
	@{ hash kubectl-build && hash kubectl-buildkit; } \
		|| curl -sL $(buildkit_cli_url) | tar -C /usr/local/bin -zxvf -

.PHONY: reqs/ytt
reqs/ytt: bin := ytt
reqs/ytt: bin_url := https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.37.0/ytt-linux-amd64
reqs/ytt:
	@hash $(bin) || \
		{ TMPDIR="$$(mktemp -d)" && \
		curl -Lo $$TMPDIR/$(bin) $(bin_url) && \
		install $$TMPDIR/$(bin) $(HOME)/.local/bin/ && \
		rm -r $$TMPDIR; }

.PHONY: reqs/kbld
reqs/kbld: bin := kbld
reqs/kbld: bin_url := https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.31.0/kbld-linux-amd64
reqs/kbld:
	@hash $(bin) || \
		{ TMPDIR="$$(mktemp -d)" && \
		curl -Lo $$TMPDIR/$(bin) $(bin_url) && \
		install $$TMPDIR/$(bin) $(HOME)/.local/bin/ && \
		rm -r $$TMPDIR; }

.PHONY: reqs/kapp
reqs/kapp: bin := kapp
reqs/kapp: bin_url := https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.42.0/kapp-linux-amd64
reqs/kapp:
	@hash $(bin) || \
		{ TMPDIR="$$(mktemp -d)" && \
		curl -Lo $$TMPDIR/$(bin) $(bin_url) && \
		install $$TMPDIR/$(bin) $(HOME)/.local/bin/ && \
		rm -r $$TMPDIR; }

.PHONY: reqs/kwt
reqs/kwt: bin := kwt
reqs/kwt: bin_url := https://github.com/vmware-tanzu/carvel-kwt/releases/download/v0.0.6/kwt-linux-amd64
reqs/kwt:
	@hash $(bin) || \
		{ TMPDIR="$$(mktemp -d)" && \
		curl -Lo $$TMPDIR/$(bin) $(bin_url) && \
		install $$TMPDIR/$(bin) $(HOME)/.local/bin/ && \
		rm -r $$TMPDIR; }
