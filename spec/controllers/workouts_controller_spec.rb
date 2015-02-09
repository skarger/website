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

    context 'when the user is logged in' do
      let(:workout) { Workout.new(id: 1) }
      let(:user) { User.new(id: 1) }

      before(:each) do
        allow(subject).
          to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:new).and_return(workout)
      end

      it 'should redirect to the new workout' do
        allow(Workout).to receive(:new).and_return(workout)

        post :create, workout: { where: "Gym"}
        expect(response).to redirect_to(workout_path(workout))
      end

      it 'should set the workout user to currently logged in user' do
        post :create, workout: { where: "Gym"}
        expect(workout.user).to eql(user)
      end
    end
  end
end
