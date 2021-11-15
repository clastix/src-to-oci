include ./utils/misc.Makefile
include ./utils/reqs.Makefile

.PHONY: reqs
reqs: reqs/cluster reqs/kapp-controller reqs/regsitry-creds reqs/buildkit/server reqs/buildkit/rbac

.PHONY: app/rbac
app/rbac:
	@$(kubectl) -n default apply -f ./rbac/simpleapp/serviceaccount.yaml
	@$(kubectl) -n default apply -f ./rbac/simpleapp/rolebinding.yaml
