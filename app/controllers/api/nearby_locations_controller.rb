class Api::NearbyLocationsController < Api::BaseController
  WITHIN_METERS = 100

  def show
    begin
      locations = Location.where(
        "ST_DWithin(point, 'POINT( #{longitude} #{latitude} )', #{WITHIN_METERS})"
      )
    rescue ActionController::ParameterMissing => e
      render json: {
        errors: [{
          status: "400",
          title: "missing query parameters",
          detail: "must provide latitude and longitude"
        }]
      }, status: :bad_request and return
    end

    render json: {
      data: locations.map do |l|
        serialize_location(l)
      end
    }
  end

  private

  def coordinate_params
    params.permit(:latitude, :longitude)
  end

  def latitude
    coordinate_params.require(:latitude)
  end

  def longitude
    coordinate_params.require(:longitude)
  end

  def serialize_location(location)
    {
      type: "locations",
      id: location.id.to_s,
      attributes: {
        name: location.name,
        latitude: location.point.y,
        longitude: location.point.x
      }
    }
  end
end
