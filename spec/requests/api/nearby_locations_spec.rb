require 'rails_helper'

describe "/api/nearby_locations", type: :request do
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
end
