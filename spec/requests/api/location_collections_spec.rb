require 'rails_helper'

describe "/api/location_collections", type: :request do
  it "responds with 204 NO CONTENT" do
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
    expect(response.code).to eq("204")
  end

  it "writes locations to DB" do
  end

  it "creates locations transactionally" do
  end
end
