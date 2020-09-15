# Kahoy-app-deploy-example

This example shows a simple and reliable way of deploying kubernetes apps easily.

## Features

- Different environment deployments (staging and production).
- Multiple applications (DRY using [Helm] templates).
- Abstraction layer for deployment configuration (`config.yaml`).
- Easy way of updating version of the apps.
- Gitops based on github actions (With dry-run, diff stages)
- [Kahoy] for deployments.
- Wait deployments finish and be ready (using [Kubedog]).
- Templated generic service (ingress, HPA, deployment, monitoring...).
- Optional app configuration inheritance.

## How does it work

We are using a single tool for each step:

- Step 1: Generate Kubernetes manifests.
- Step 2: Deploy Kubernetes manifests.
- Step 3: Wait for these resources to be ready.

### Step 1: Kubernetes manifests generation

We have a generic helm chart ready to be used to generate the required manifests to deploy a service on Kubernetes.

We are only using helm for rendering, the generic chart comes with:

- Deployment + service
- Autoscaling
- Ingress
- Monitoring

We have set default values, so applications only need to configure whatever they required. This will create our abstraction layer so users don't need to craft huge YAML manifests to deploy a generic service.

- [`./charts`](charts/): Generic [Helm] chart.
- [`./_gen`](_gen/): Generated manifests (these are the ones that will be deployed).
- [`./services`](services/): Our applications, with their version, configuration.

#### Services structure

Our services have this structure `services/{SERVICE}/{ENV}`, e.g:

```text
├── app1
│   ├── staging
│   └── production
└── app2
    └── production
```

This will generate 3 applications:

- `app1` in `staging`.
- `app1` in `production`.
- `app2` in `production`.

To configure the services, we need `config.yaml` and `version` files to generate the required Kubernetes YAMLs.

The envs can inherit the app level configuration and version if they don't redefine values, however `config.yaml` file must exist on app and env level (can be empty). e.g:

```text
├── app1
│   ├── config.yaml         `app1-root-config`
│   ├── production
│   │   ├── config.yaml     `app1-prod-config`
│   │   └── version         `app1-prod-version`
│   ├── staging
│   │   └── config.yaml     `app1-staging-config`
│   └── version             `app1-root-version`
└── app2
    ├── config.yaml         `app2-root-config`
    └── production
        ├── config.yaml     `app2-prod-config`
        └── version         `app2-prod-version`
```

This would produce this:

- app1 production: `app1-root-config` + `app1-prod-config` and `app1-prod-version`.
- app1 staging: `app1-root-config` + `app1-staging-config` and `app1-root-version`.
- app2 production: `app2-root-config` + `app2-prod-config` and `app2-prod-version`.

#### Generated structure

We want to deploy the apps by env, so, to give flexibility, we are generating the envs in `_gen/{ENV}/{SERVICE}` structure. e.g:

```text
./_gen/
├── production
│   ├── app1
│   │   └── resources.yaml
│   └── app2
│       └── resources.yaml
└── staging
    └── app1
        └── resources.yaml
```

Now to deploy to different envs we can use `_gen/production` and `_gen/staging`, or if we add more envs, `_gen/xxxxxx`.

#### How to generate

With `make generate` Will regenerate everything, if any of the resources has been deleted (e.g an application, and ingress...), these will be removed from the generated files.

All this generation logic can be checked in [`scripts/generate.sh`](scripts/generate.sh).

### Step 2: Deploy to Kubernetes

We will use [Kahoy] to deploy to Kubernetes. [Kahoy] is a great tool for raw manifests, it handles the changes based on 2 manifest states. For example the manifests from one commit with the manifests from other commit, that way knows what has been added, changed, deleted..., these are the main features we need:

- Understands Kubernetes resources.
- Has dry-run and diff stages.
- Understands Git
- Can deploys only the changes between 2 states (e.g K8s manifests of 2 git commits).
- Garbage collects.
- Uses kubectl under the hoods to deploy, no magic.

This simplifies everything because we don't depend on a specific tool, we are deploying Raw kubernetes manifests in a smart way:

- Tomorrow you could change helm with Kustomize.
- Deploy raw kubernetes manifests with our generated apps.
- We don't mutate our manifests with labels.
- Simple Kubectl applies done in a smart way.

All the dpeloy commands can be see in [`scripts/deploy.sh`](scripts/deploy.sh).

With this we will create some github action workflows of Dry-run, diff, apply (only changes), apply (full sync)...

### Step 3: Deployment Feedback

Deploy feedback means the feedback that we get after a deployment, not everyone wants this, but some companies are used to wait unit the deployment is ready to mark the deployment as good or bad.

[Kahoy] solves this by giving the user an optional report of what applied. With this report we can know what we need to wait for.

To wait we will use [Kubedog], Kubedog knows how to wait Kubernetes core workloads, these are `Deployments`, `StatefulSets`, `Jobs` and `Daemonsets`.

So in a few words, we will take the output of [Kahoy], and pass it through Kubedog so it will wait until all the resources are ready (e.g replicas of a deployment updated).

We also can wait for deleted resources, for this, we use `kubetcl wait`.

All this waiting logic can be checked in [`scripts/wait.sh`](scripts/wait.sh).

## CI

TODO

[helm]: https://github.com/helm/helm
[kahoy]: https://github.com/slok/kahoy
[kubedog]: https://github.com/werf/kubedog
