require 'rails_helper'

describe "/api/nearby_locations", type: :request do
  it "responds with error if lat/lng not given" do
    get api_nearby_locations_path,
      params: {}
    expect(response.code).to eq("400")
    expect(response.body).to match_json_expression({
      errors: [{
        status: "400",
        title: "missing query parameters",
        detail: "must provide latitude and longitude"
      }]
    })
  end

  it "responds with empty data if no nearby locations" do
    get api_nearby_locations_path,
      params: {
        latitude: 142.45,
        longitude: -71.53
      }
    expect(response.code).to eq("200")
    expect(response.body).to match_json_expression({
      data: []
    })
  end

  it "responds with stops within 100m of given lat/lng" do
    lat = 42.3356155
    lng = -71.0353174

    lat_67m = 42.335614
    lng_67m = -71.0345

    lat_101m = 42.335615493451
    lng_101m = -71.0340918798235
    nearby_location = Location.create!(
      name: "Nearby", point: "POINT ( #{lng_67m} #{lat_67m})"
    )
    non_nearby_location = Location.create!(
      point: "POINT ( #{lng_101m} #{lat_101m})"
    )

    get api_nearby_locations_path,
      params: {
        latitude: lat,
        longitude: lng
      }
    expect(response.body).to match_json_expression({
      data: [{
        type: "locations",
        id: nearby_location.id.to_s,
        attributes: {
          name: nearby_location.name,
          latitude: nearby_location.point.y,
          longitude: nearby_location.point.x
        }
      }]
    })
  end
end
