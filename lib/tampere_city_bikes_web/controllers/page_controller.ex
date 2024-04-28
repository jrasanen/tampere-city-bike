defmodule TampereCityBikesWeb.PageController do
  use TampereCityBikesWeb, :controller
  alias TampereCityBikes.UrbanSharing

  def home(conn, _params) do
    case UrbanSharing.query_dock_groups do
      {:ok, %{dockGroups: dock_groups}} ->
        points = Enum.map(dock_groups, fn %{
          :coord => %{:lat => lat, :lng => lng},
          :title => title,
          :availabilityInfo => %{
            :availableVehicles => availableVehicles,
            :availableDocks => availableDocks
          }
        } ->
          %{
            "lat" => lat,
            "lon" => lng,
            "title" => title,
            "availableDocks" => availableDocks,
            "availableVehicles" => availableVehicles
          }
        end)
        render(conn, :home, dock_groups: Jason.encode!(points))

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Data not found.")
        |> render(conn, :home)
    end
  end
end
