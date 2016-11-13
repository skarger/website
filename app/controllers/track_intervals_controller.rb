class TrackIntervalsController < ApplicationController
  before_action :require_login, except: [:index, :show]

  def new
    @track_interval = TrackInterval.new
    @workout = Workout.find(params[:workout_id])
    @track_interval.track_workout = @workout

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @track_interval }
    end
  end

  def create
    @track_interval = TrackInterval.new(track_interval_params)

    @track_workout = TrackWorkout.find(params["workout_id"])
    @track_interval.track_workout = @track_workout

    respond_to do |format|
      if @track_interval.save
        format.html { redirect_to workout_url(@track_workout), notice: 'Track Interval was successfully created.' }
      end
    end
  end

  private
  def track_interval_params
    params.require(:track_interval).permit(:order, :distance_in_meters, :time, :rest)
  end

  def require_login
    if logged_in?
      associated_workout = Workout.find(params[:workout_id])
      if associated_workout.user_id != current_user.id
        render_404
      end
    else
      redirect_to login_path
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_404
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  end
end
