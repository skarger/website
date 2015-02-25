require 'rails_helper'

RSpec.describe RunIntervalsController, :type => :controller do
  describe '#new' do
    let(:user) { User.new(id: 1) }
    let(:workout) { SpeedWorkout.new(id: 1, user_id: user.id) }

    before(:each) do
      allow(Workout).to receive(:find).and_return(workout)
    end

    context 'when the user is not logged in' do
      it 'should redirect to login' do
        get :new, workout_id: workout.id
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when the logged in user does not own the workout' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        logged_in_user = User.new(id: 2)
        allow(subject).to receive(:current_user).and_return(logged_in_user)
        get :new, workout_id: workout.id
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in but the workout does not exist' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).
          and_raise(ActiveRecord::RecordNotFound)
        get :new, workout_id: -1
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in and owns the workout' do
      before(:each) do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
      end

      it 'should return OK' do
        get :new, workout_id: workout.id
        expect(response.code).to eq("200")
      end

      it 'should have the correct workout id set' do
        run_interval = RunInterval.new
        allow(RunInterval).to receive(:new).and_return(run_interval)
        get :new, workout_id: workout.id
        expect(run_interval.speed_workout_id).to eq(workout.id)
      end
    end
  end

  describe '#create' do
    let(:user) { User.new(id: 1) }
    let(:workout) { SpeedWorkout.new(id: 1, user_id: user.id) }

    it 'should redirect to login if the user is not logged in' do
      post :create, workout_id: workout.id
      expect(response).to redirect_to(login_path)
    end

    context 'when the logged in user does not own the workout' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        logged_in_user = User.new(id: 2)
        allow(subject).to receive(:current_user).and_return(logged_in_user)
        post :create, workout_id: workout.id
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in but the workout does not exist' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).
          and_raise(ActiveRecord::RecordNotFound)
        post :create, workout_id: -1
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in and owns the workout' do
      let(:run_interval) { RunInterval.new }

      before(:each) do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).and_return(workout)
        allow(RunInterval).to receive(:new).and_return(run_interval)
      end

      it 'should redirect to the workout' do
        post :create, workout_id: workout.id
        expect(response).to redirect_to(workout_path(workout))
      end

      it "should set the created run interval's workout to the workout" do
        post :create, workout_id: workout.id
        expect(run_interval.speed_workout_id).to eql(workout.id)
      end
    end
  end
end
