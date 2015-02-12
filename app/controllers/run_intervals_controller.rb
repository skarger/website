class RunIntervalsController < ApplicationController
  before_action :require_login, except: [:index, :show]

  def new
    @run_interval = RunInterval.new
    @workout = Workout.find(params[:workout_id])
    @run_interval.speed_workout_id = @workout.id

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_interval }
    end
  end

  private
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
