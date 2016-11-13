require "rails_helper"

RSpec.describe "workouts/show", :type => :view do
  context 'when the workout is a Track Workout' do

    let(:user) { User.new }
    let(:workout) {
      Workout.new(id: 1, type: 'TrackWorkout',
        when: DateTime.now, user: user)
    }

    before(:each) do
      assign(:workout, workout)
    end

    context 'when the user is not logged in' do
      before(:each) do
        allow(view).to receive(:logged_in?).and_return(false)
      end

      it "should not have a link to add a track interval" do
      render
      expect(rendered).not_to match /Add track interval/
      end
    end

    context 'when the user is logged in but does not own the workout' do
      it "should should have a link to add a track interval" do
        allow(view).to receive(:logged_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(User.new)
        render
        expect(rendered).not_to match /Add track interval/
      end
    end


    context 'when the user is logged in and owns the workout' do
      it "should have a link to add a track interval" do
        allow(view).to receive(:logged_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        render
        expect(rendered).to match /Add track interval/
      end
    end

  end

  context "when the workout is a Distance Workout" do
    it "should render a page customized to a Distance Workout" do
      workout = Workout.new(id: 2, type: 'DistanceWorkout',
        when: DateTime.now)
      assign(:workout, workout)
      render
      expect(rendered).to match /Distance Workout/
    end

    it "should show the date" do
      today = DateTime.now
      workout = Workout.new(id: 2, type: 'DistanceWorkout',
        when: today)
      assign(:workout, workout)
      render
      expect(rendered).to match /Distance Workout | #{today.strftime('%b %d %Y')}/
    end
  end

end
