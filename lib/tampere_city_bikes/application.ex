defmodule TampereCityBikes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TampereCityBikes.UrbanSharing.Cache,
      TampereCityBikesWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tampere_city_bikes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TampereCityBikes.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TampereCityBikes.Finch},
      # Start a worker by calling: TampereCityBikes.Worker.start_link(arg)
      # {TampereCityBikes.Worker, arg},
      # Start to serve requests, typically the last entry
      TampereCityBikesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TampereCityBikes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TampereCityBikesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
