require 'rails_helper'

describe "/api/location_collections", type: :request do
  it "responds with 422 if invalid data given" do
    post_data = {
      'spots': []
    }
    post api_location_collections_path, params: post_data
    expect(response.code).to eq("400")
    expect(response.body).to match_json_expression({
      errors: [{
        status: "400",
        title: "bad_request",
        detail: "invalid location data"
      }]
    })
  end

  it "handles an empty list of locations" do
    post_data = {
      'data': []
    }
    post api_location_collections_path, params: post_data
    expect(response.code).to eq("204")
  end

  it "writes locations to DB" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    post_data = {
      'data': [{
        id: uuid1,
        type: 'locations',
        attributes: {
          name: 'Winterfell',
          latitude: 1.23,
          longitude: -4.56
        }
      }, {
        id: uuid2,
        type: 'locations',
        attributes: {
          name: 'Moat Cailin',
          latitude: 7.89,
          longitude: -0.12
        },
      }]
    }

    post api_location_collections_path, params: post_data

    passed = post_data[:data].map do |l|
      {
        id: l[:id],
        name: l[:attributes][:name],
        latitude: l[:attributes][:latitude],
        longitude: l[:attributes][:longitude]
      }
    end
    written = Location.all.map do |l|
      {
        id: l.uuid,
        name: l.name,
        latitude: l.point.y,
        longitude: l.point.x
      }
    end
    expect(written).to match_array(passed)
  end

  it "creates locations transactionally" do
    uuid1 = SecureRandom.uuid
    uuid2 = SecureRandom.uuid

    post_data = {
      'data': [{
        id: uuid1,
        type: 'locations',
        attributes: {
          name: 'Winterfell',
          latitude: 1.23,
          longitude: -4.56
        }
      }, {
        id: uuid2,
        type: 'locations',
        attributes: {
          name: 'Moat Cailin',
          latitude: 7.89,
          longitude: -0.12
        },
      }]
    }

    # uuid must be unique, so creation will fail if location with given uuid exists
    Location.create(uuid: uuid1)

    post api_location_collections_path, params: post_data

    expect(response.code).to eq("409")
    expect(Location.count).to eq(1)
  end
end
