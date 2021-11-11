# Give me your code: I give you back your OCI image

#### Building and shipping images like a pro!

## Quickstart

1. **Configure the requisites**

```sh
make reqs
```

2. **Configure the identity that the controller will assume to reconcile a sample app**

```sh
make app/rbac
```

3. **Build and deploy (Go and NodeJS) sample apps**

```sh
kubectl apply -f ./{go,nodejs}-simpleapp.yaml
```

## The architecture

```
                    │
          Consumer  │   Platform
          space     │   space
                    │                        ┌──────────────────────────────────┐
                    │                        │  Kapp Controller                 │
                    │                        │                      | Reconcile |
┌───────────────┐   │   ┌───────────────┐    │    ┌─────────────┐   │           │
│  App Source   │   │   │  App Config   │    │    │             │   │           │
│  Repository   │   │   │ ┌──────────┐  │    │    │ Ytt         │   │           │
│ ┌──────────┐  |◄──┼───┼─┤ Fetch    │  │◄───┤    │             │   │           │
│ │ Source   │  │   │   │ │ Config   |  |    │    └──────┬──────┘   │           │
│ │ code     │  │   │   │ ├──────────┤  │    │           │ Templating           │
│ ├──────────┤  │   │   │ │ Build    │  │    │    ┌──────▼──────┐   │           │
│ │ Container│  │   │   │ │ Config   │  │    │    │             │   │ Image digest resolution
│ │ file     │  │   │   │ ├──────────┤  │    │    │ Kbld        │───┼───────────┬─────────────►
│ └──────────┘  │   │   │ │ Deploy   │  │    │    │             │   │ Config recording
│               │   │   │ │ Config   │  │    │    └──────┬──────┘   ▼           │
│               │   │   │ └──────────┘  │    │       Orchestrating  |           |
│               │   │   │               │    │    ┌──────▼──────┐   │           │
└───────────────┘   │   └───────────────┘    │    │             │   │           │
                    │                        │    │ Buildkit    │   │           │
                    │                        │    │             │   │           │
                    │                        │    └──────┬──────┘   │           │
                    │                        │           │ Image building       │
                    │                        │    ┌──────▼──────┐   │           │
                    │                        │    │             │   │           │
                    │                        │    │ OCI Image   │   │           │
                    │                        │    │             │   │           │
                    │                        │    └──────┬──────┘   │           │
                    │                        │           │ Image pushing        │
┌───────────────┐   │                        │    ┌──────▼──────┐   │           │
│               │   │                        │    │             │   │           │
│  App Image    |◄──┼────────────────────────┼────┤ OCI Registry│   │ Kbld      │
│               │   │                        │    │             │   │ config    │
└───────────────┘   │                        │    └─────────────┘   │ result    |
                    │                        │                      ▼           │
┌───────────────┐   │                        │    ┌────────────────────┐        │
│               │   │                        │    │                    |        │
│  App API      |◄──┼────────────────────────┼────┤ Kapp deploy        |        |
│               │   │                        │    │                    |        |
└───────────────┘   │                        │    └────────────────────┘        │
                    │                        │                                  │
                    │                        └──────────────────────────────────┘
                    │
                    │
```

## Prerequisite

A Kubernetes cluster must be initialized, you can use `kind` to scaffold a local one.

```
kind create cluster --name oci
```

### Install the Kapp Controller

`kapp-controller` is the GitOps engine and CI/CD engine behind the PoC.

Actually, it must be installed using the container image `quay.io/maxgio92/kapp-controller:v0.20.0-feat-buildkit` due to some hotfixes not yet ported in the `upstream`.

```shell
kubectl apply -f ./kapp-controller
```

### Ensure that `buildkit` has been deployed in `kapp-controller` Namespace.

`buildkit` will be the builder to compile the OCI images using the `containerd` socket.

```shell
kubectl buildkit create --config=./buildkit/config.toml
```

> Installation should be performed in an idempotent way by the `kapp-controller` at first run, we like to play safe.

### Ensure that the `buildkit` ConfigMap is using the right configuration

For the PoC, we have to ensure being able to push to a local repository that is self-hosted in the cluster: this means to TLS to keep the setup as streamline and no burderning as possible.

```shell
cat ./buildkit/config.toml
debug = true
[worker.containerd]
  namespace = "k8s.io"
[registry."registry.default:5000"]
  http = true
  insecure = true
```

```shell
kubectl -n kapp-controller create configmap buildkit --from-file=./buildkit/config.toml --dry-run=client -o yaml | kubectl apply -f -
```

### Deploy the Registry

We have to host our images, the easier way is having a local registry.

```shell
kubectl -n default apply -f ./registry
```

### Ensure the `kubectl-buildkit` RBAC is well configured

This is required to allow `kubectl-buildkit` binary to connect to the `buildkit` pods running in the same Namespace.

```shell
kubectl -n kapp-controller apply -f ./rbac/kubectl-buildkit/clusterrole.yaml
```

```shell
kubectl -n kapp-controller apply -f ./rbac/kubectl-buildkit/rolebinding.yaml
```

### Create the `simpleapp` required RBAC for the App definition.

Each App resource will grant permission to a specific Namespace following the least privilege principle security: the `simpleapp` will be able to manipulate resources just in its Namespace.

This is achievable creating a _Service Account_ that will be used by `kapp` to interact with the Kubernetes APIs.

```shell
kubectl -n default apply -f ./rbac/simpleapp/serviceaccount.yaml
```

```shell
kubectl -n default apply -f ./rbac/simpleapp/rolebinding.yaml
```

### Finally, deploy the App manifest

```shell
kubectl -n default apply -f app.yaml
```

After a while, you'll end up with your Kubernetes resources deployed in the `default` Namespace, along with the built image in the registry!

You can check the pushed image doing a `kubectl -n default port-forward svc/registry 5000` and performing a curl as follows:

```
curl -s localhost:5000/v2/dkalinin/k8s-simple-app/tags/list | jq
{
  "name": "dkalinin/k8s-simple-app",
  "tags": [
    "rand-1636035802052238426-23020512585110-simple-app",
    "rand-1636035879761363148-23661231108212-simple-app",
    "rand-1636035573732647161-15319724092168-simple-app",
    "rand-1636035689187581038-62121151971-simple-app",
    "rand-1636035765142987597-237186124193138-simple-app",
    "rand-1636035536302191351-6313325222646-simple-app",
    "rand-1636035612490018087-4089132189189-simple-app",
    "rand-1636035727340293068-13312016318875-simple-app",
    "rand-1636035650671132368-2062444129177-simple-app",
    "rand-1636035841539707777-21542242238171-simple-app"
  ]
}
```
