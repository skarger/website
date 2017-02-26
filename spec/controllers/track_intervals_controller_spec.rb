require 'rails_helper'

RSpec.describe TrackIntervalsController, :type => :controller do
  describe '#new' do
    let(:user) { User.new(id: 1) }
    let(:workout) { TrackWorkout.new(id: 1, user_id: user.id) }

    before(:each) do
      allow(Workout).to receive(:find).and_return(workout)
    end

    context 'when the user is not logged in' do
      it 'should redirect to login' do
        get :new, params: { workout_id: workout.id }
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when the logged in user does not own the workout' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        logged_in_user = User.new(id: 2)
        allow(subject).to receive(:current_user).and_return(logged_in_user)
        get :new, params: { workout_id: workout.id }
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in but the workout does not exist' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).
          and_raise(ActiveRecord::RecordNotFound)
        get :new, params: { workout_id: -1 }
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in and owns the workout' do
      before(:each) do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
      end

      it 'should return OK' do
        get :new, params: { workout_id: workout.id }
        expect(response.code).to eq("200")
      end

      it 'should have the correct workout id set' do
        track_interval = TrackInterval.new
        allow(TrackInterval).to receive(:new).and_return(track_interval)
        get :new, params: { workout_id: workout.id }
        expect(track_interval.track_workout_id).to eq(workout.id)
      end
    end
  end

  describe '#create' do
    let(:user) { User.new(id: 1) }
    let(:workout) { TrackWorkout.new(id: 1, user_id: user.id) }

    it 'should redirect to login if the user is not logged in' do
      post :create, params: { workout_id: workout.id }
      expect(response).to redirect_to(login_path)
    end

    context 'when the logged in user does not own the workout' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        logged_in_user = User.new(id: 2)
        allow(subject).to receive(:current_user).and_return(logged_in_user)
        post :create, params: { workout_id: workout.id }
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in but the workout does not exist' do
      it 'should return not found' do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).
          and_raise(ActiveRecord::RecordNotFound)
        post :create, params: { workout_id: -1 }
        expect(response.code).to eq("404")
      end
    end

    context 'when the user is logged in and owns the workout' do
      let(:track_interval) { TrackInterval.new }

      before(:each) do
        allow(subject).to receive(:logged_in?).and_return(true)
        allow(subject).to receive(:current_user).and_return(user)
        allow(Workout).to receive(:find).and_return(workout)
      end

      it "should require a track_interval" do
        expect{ post :create, params: { workout_id: workout.id } }.to raise_error ActionController::ParameterMissing
      end

      it "should permit valid track interval attributes" do
        valid_track_interval = TrackInterval.new(order: 1, distance_in_meters: 200, time: 35, rest: 90)
        post :create, params: { workout_id: workout.id, track_interval: valid_track_interval.as_json }
        expect(response.code).to eq("302")
      end

      it "should not permit invalid track interval attributes" do
        # user should not be able to set id of created track interval object
        invalid_attributes = { id: -1 }
        post :create, params: { workout_id: workout.id, track_interval: invalid_attributes }
        interval_ids = Workout.find(workout.id).track_intervals.map(&:id)
        expect(interval_ids).to_not include(-1)
      end

      it "should set the created track interval's workout to the workout" do
        allow(TrackInterval).to receive(:new).and_return(track_interval)
        post :create, params: { workout_id: workout.id, track_interval: track_interval.as_json }
        expect(track_interval.track_workout_id).to eql(workout.id)
      end

      it 'should redirect to the workout' do
        post :create, params: { workout_id: workout.id, track_interval: track_interval.as_json }
        expect(response).to redirect_to(workout_path(workout))
      end

    end
  end
end