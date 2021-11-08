.PHONY: kind
kind:
	@$(kind) create cluster --name oci || true

.PHONY: cleanup
cleanup:
	@$(kind) delete cluster --name oci || true

.PHONY: purge
purge: cleanup
	@$(kind) delete cluster

.PHONY: copy-images
copy-images:
	@kubectl port-forward -n default svc/registry 5000 &>/dev/null &
	@skopeo copy \
		--src-tls-verify=false \
		--dest-tls-verify=false \
		docker://registry:5001/dkalinin/k8s-simple-app:0.0.1 \
		docker://registry:5000/dkalinin/k8s-simple-app:0.0.1

.PHONY: local-registry
local-registry:
	@docker run -d --restart=always -p "127.0.0.1:5001:5000" --name registry registry:2 \
	2> /dev/null || true

.PHONY: buildkit/build
buildkit/build: reqs
	$(kubectl) buildkit create --config ./config/buildkit/config.toml
	$(kubectl) buildkit build --push -t $(IMAGE) .

.PHONY: ytt/template
ytt/template:
	@$(ytt) -f ./config

.PHONY: kbld/build
kbld/build:
	$(MAKE) -s template | $(kbld) -f -

.PHONY: build
build: kbld/build
