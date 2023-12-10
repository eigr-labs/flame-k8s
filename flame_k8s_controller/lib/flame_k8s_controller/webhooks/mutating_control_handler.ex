defmodule FlameK8sController.Webhooks.MutatingControlHandler do
  @moduledoc """
  Mutating Webhook Handler for Postgres Kompo
  """
  use K8sWebhoox.ResourceConversion.Handler

  def convert(
        %{"apiVersion" => "apps/v1", "kind" => "Deployment"} = resource,
        "apps/v1"
      ) do
        # TODO inject envs
    {:ok, put_in(resource, ~w(metadata labels), %{"foo" => "bar"})}
  end

  def convert(
        %{"apiVersion" => "apps/v1", "kind" => "StatefulSet"} = resource,
        "apps/v1"
      ) do
        # TODO inject envs
    {:ok, put_in(resource, ~w(metadata labels), %{"foo" => "bar"})}
  end
end
