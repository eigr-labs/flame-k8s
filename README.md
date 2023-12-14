# Flame K8s Adapter

Flame k8s Adapter.

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
        flame-eigr.io/enabled: "true"
        flame-eigr.io/dist-auto-config: "true"
        flame-eigr.io/otp-app: "my_app_release_name"
    spec:
      containers:
        - image: eigr/spawn-operator:1.1.1
          name: spawn-operator
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
      flame-eigr.io/enabled: "true"
      flame-eigr.io/dist-auto-config: "true"
      flame-eigr.io/otp-app: "my_app_release_name"
```

See what each annotation means in the following table:

| Annotation                     | Default          | Detail        |
| ------------------------------ | -----------------| ------------- | 
| flame-eigr.io/enabled          | "false"          | Enable flame. |
| flame-eigr.io/dist-auto-config | "false"          | Configure RELEASE_DISTRIBUTION and RELEASE_NODE based on otp application name. |
| flame-eigr.io/otp-app          |                  | Application release name. Required if dist-auto-config is set to "true".  |
| flame-eigr.io/pool-config-ref  | "default-pool"   | Flame Pool configuration file name. See more in the Configuration section.           |

Now you can start scaling your applications with Flame \0/

## Configuration

TODO