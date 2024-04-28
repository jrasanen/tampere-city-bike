defmodule TampereCityBikes.UrbanSharing do
  require HTTPoison

  def query_dock_groups do
    case TampereCityBikes.UrbanSharing.Cache.read(:dock_groups) do
      {:ok, %{data: value}} ->
        {:ok, value}

      {:error, :expired} ->
        fetch_and_cache_dock_groups()

      {:error, :not_found} ->
        fetch_and_cache_dock_groups()
    end
  end

  defp fetch_and_cache_dock_groups do
    url = "https://core.urbansharing.com/public/api/v1/graphql"
    headers = [
      {"content-type", "application/json"},
      {"systemId", "inurba-tampere"}
    ]
    body = %{
      query: """
      query {
        dockGroups {
          id
          name
          title
          state
          subTitle
          enabled
          availabilityInfo {
            availableVehicles
            availableDocks
            availableVirtualDocks
            availablePhysicalDocks
            availableVehicleCategories {
              category
              count
            }
          }
          coord {
            lat
            lng
          }
        }
      }
      """
    } |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body, keys: :atoms) do
          {:ok, decoded} ->
            TampereCityBikes.UrbanSharing.Cache.write(:dock_groups, response_body)
            %{data: value} = decoded
            {:ok, value}

          {:error, _reason} ->
            {:error, :response_decode_error}
        end

      {:error, _reason} = error ->
        error
    end
  end
end
