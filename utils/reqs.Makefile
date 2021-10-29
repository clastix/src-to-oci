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
reqs/kapp-controller:
	@$(kapp) deploy -y -a kc -f ./config/kapp-controller

# Local run requirements

.PHONY: reqs/buildkit-for-kubectl
reqs/buildkit-for-kubectl:
	{ hash kubectl-build && hash kubectl-buildkit; } \
		|| curl -sL $(buildkit_cli_url) | tar -C /usr/local/bin -zxvf -

.PHONY: reqs/cluster-registry
reqs/cluster-registry:
	$(kapp) deploy --yes -a registry -f ./config/registry/cluster-registry.yml

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

reqs/kwt: bin := kwt
reqs/kwt: bin_url := https://github.com/vmware-tanzu/carvel-kwt/releases/download/v0.0.6/kwt-linux-amd64
reqs/kwt:
	@hash $(bin) || \
		{ TMPDIR="$$(mktemp -d)" && \
		curl -Lo $$TMPDIR/$(bin) $(bin_url) && \
		install $$TMPDIR/$(bin) $(HOME)/.local/bin/ && \
		rm -r $$TMPDIR; }
