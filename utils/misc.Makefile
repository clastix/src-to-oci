.PHONY: kind
kind:
	@$(kind) create cluster 2> /dev/null || true

.PHONY: cleanup
cleanup:
	@$(kapp) delete --yes -a $(APP)

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
