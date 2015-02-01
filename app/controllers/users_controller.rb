class UsersController < ApplicationController
  before_action :block_in_production
  skip_before_action :block_in_production, only: [:show]

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "Sign Up Successful"
      log_in(@user)
      redirect_to @user
    else
      render 'new'
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def block_in_production
      # until we actually want people to sign up let's not allow it in production
      if Rails.env.production?
        render file: "#{Rails.root}/public/404.html", status: 404
      end
    end

end
