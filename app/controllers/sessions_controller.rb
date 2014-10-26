class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      # log in
    else
      Rails.logger.info("unsuccessful login attempt")
      render 'new'
    end
  end

  def destroy
  end

end
