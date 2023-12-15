# Flame K8s Adapter

Advanced [Flame](https://github.com/phoenixframework/flame) [k8s](https://kubernetes.io) Adapter basead on [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flame_k8s` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flame_k8s, "~> 0.1.0"}
  ]
end
```

> **_NOTE:_** You need to install our Kubernetes Controller in the Kubernetes where you want to run your application. Follow the instructions below

### Install Kubernetes Controller

TODO

## Usage

Configure the flame backend in our configuration.

```elixir
# config.exs
if config_env() == :prod do
  config :flame, :backend, FLAME.K8sBackend
  config :flame, FLAME.K8sBackend, log: :debug
end
```

You need to enable Flame in Kubernetes as well. See the example below:

```yaml
# my-application.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flame-parent-example
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flame-parent-example
  template:
    metadata:
      annotations:
        flame.org/enabled: "true"
        flame.org/dist-auto-config: "true"
        flame.org/otp-app: "my_app_release_name"
    spec:
      containers:
        - image: eigr/flame-parent-example:1.1.1
          name: flame-parent-example
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 200m
              memory: 200Mi
```

The most important part is:

```yaml
template:
  metadata:
    annotations:
      flame.org/enabled: "true"
      flame.org/dist-auto-config: "true"
      flame.org/otp-app: "my_app_release_name"
```

See what each annotation means in the following table:

| Annotation                           | Default          | Detail        |
| -------------------------------------| -----------------| ------------- | 
| flame.org/enabled                    | "false"          | Enable Flame. |
| flame.org/dist-auto-config           | "false"          | Auto configure RELEASE_DISTRIBUTION and RELEASE_NODE based on otp application name.             |
| flame.org/otp-app                    |                  | Application release name. Required if dist-auto-config is set to "true".  |
| flame.org/pool-config-ref            | "default-pool"   | Flame Pool configuration reference name. See more in the Configuration section.           |
| flame.org/runner-termination-timeout | 60000            | Timeout in milliseconds that the Runner will have to finish before the controller sends the POD delete command.

Now you can start scaling your applications with [Flame](https://github.com/phoenixframework/flame)... with a little help from [eigr](https://github.com/eigr) \0/

## Configuration

TODO

### 1. Flame Runner Pool

The Flame k8s Controller gives you the possibility to configure different runner profiles. These profiles will be used when creating PODs to run Runners in Kubernetes.
To configure a new Runner Pool, simply define the following yaml file and apply it to the Kubernetes cluster.

```yaml
# my-runner.yaml
---
  apiVersion: flame.org/v1
  kind: FlamePool
  metadata:
    name: my-runner-pool
    namespace: default
  spec:
    podTemplate:
      spec: # This is a pod template specification. See https://kubernetes.io/docs/concepts/workloads/pods/#pod-templates
        containers:
          - env:
              - name: MY_VAR
                value: "my-value"
            resources:
              limits:
                cpu: 200m
                memory: 1Gi
              requests:
                cpu: 200m
                memory: 2Gi
            volumeMounts:
              - mountPath: /app/.cache/bakeware/
                name: bakeware-cache
        volumes:
          - name: bakeware-cache
            emptyDir: {}
```

Then:

```sh
kubectl apply -f my-runner.yaml
```

Once this is done, simply add the annotation `flame.org/pool-config-ref` to your Deployment file. Example:

```yaml
# my-application.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flame-parent-example
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flame-parent-example
  template:
    metadata:
      annotations:
        flame.org/enabled: "true"
        flame.org/pool-config-ref: "my-runner-pool"
    spec:
      containers:
        - image: eigr/flame-parent-example:1.1.1
...        
```

You can also list all Runner pools configured on the system with the command:

```sh
kubectl --all-namespaces get pools
```