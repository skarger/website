require 'rails_helper'

RSpec.describe WorkoutsController, :type => :controller do
  describe '#new' do
    it 'should redirect to login if the user is not logged in' do
      get :new
      expect(response).to redirect_to(login_path)
    end

    it 'should render the new workout view if the user is logged in' do
      allow(subject).
        to receive(:logged_in?).and_return(true)
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    it 'should redirect to login if the user is not logged in' do
      post :create
      expect(response).to redirect_to(login_path)
    end

    it 'should show the new workout if the user is logged in' do
      pending
      allow(subject).
        to receive(:logged_in?).and_return(true)
      post :create
      expect(response).to render_template(:show)
    end
  end
end
