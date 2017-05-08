class Api::LocationCollectionsController < Api::BaseController
  def create
    given_locations = []
    begin
      given_locations = locations_params
    rescue ActionController::ParameterMissing => e
      render_bad_request and return
    end

    Location.transaction do
      locations = Location.create(given_locations)
      if errors(locations).present?
        render_creation_error(locations)
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def locations_params
    params.require(:data).map do |d|
      d.permit(:id).merge(
        d.require(:attributes).permit(:name, :latitude, :longitude)
      )
    end.map do |location|
      {
        uuid: location[:id],
        name: location[:name],
        point: "POINT ( #{location[:longitude]} #{location[:latitude]} )"
      }
    end
  end

  def render_bad_request
    render json: {
      errors: [{
        status: "400",
        title: "bad_request",
        detail: "invalid location data"
      }]
    }, status: :bad_request
  end

  def errors(locations)
    locations.map(&:errors).map(&:details).select {|hsh| hsh.present?}
  end

  def uuid_conflict?(locations)
    locations.map(&:errors).map(&:details)
      .flat_map {|h| h[:uuid] }
      .map {|h| h[:error]}
      .include?(:taken)
  end

  def render_creation_error(locations)
    if uuid_conflict?(locations)
      render json: {
        errors: [{
          status: "409",
          title: "conflict",
          detail: "duplicate UUID included in locations collection"
        }]
      }, status: :conflict
    else
      render json: {
        errors: [{
          status: "422",
          title: "unprocessable_entity",
          detail: "error creating locations"
        }]
      }, status: :unprocessable_entity and return
    end
  end
end
