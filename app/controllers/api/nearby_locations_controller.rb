class Api::NearbyLocationsController < Api::BaseController
  def show
    render json: {
      data: []
    }
  end
end
