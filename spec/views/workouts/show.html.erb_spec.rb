require "rails_helper"

RSpec.describe "workouts/show", :type => :view do
  it "should have an edit link if the logged in user owns the workout" do
    user = User.new
    @workout = Workout.new(id: 1, type: 'SpeedWorkout', when: DateTime.now, user: user)
    render
    expect(rendered).to match /Add run interval/
  end

end