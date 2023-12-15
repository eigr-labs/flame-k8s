defmodule FlameK8sController.Handler.FlamePoolHandler do
  @moduledoc """

  ---
  apiVersion: flame.org/v1
  kind: FlamePool
  metadata:
    name: my-runner-pool
    namespace: default
  spec:
    podTemplate:
      spec:
      containers:
        - env:
            - name: PHX_SERVER
              value: "false"
            - name: MIX_ENV
              value: prod
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          name: spawn-operator
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 200m
              memory: 200Mi
          volumeMounts:
            - mountPath: /app/.cache/bakeware/
              name: bakeware-cache
      volumes:
        - name: bakeware-cache
          emptyDir: {}
  """
  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:add, :modify] do
    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
    Bonny.Axn.success_event(axn)
  end
end
