require "rails_helper"

RSpec.describe "run_intervals/new", :type => :view do

  before(:each) do
    workout = TrackWorkout.new(id: 1)
    run_interval = RunInterval.new(track_workout_id: workout.id)
    assign(:workout, workout)
    assign(:run_interval, run_interval)
  end

  it 'should have an input for the order of the interval' do
    render
    expect(rendered).to match(/Order/)
  end

  it 'should have an input box for distance in meters' do
    render
    expect(rendered).to match(/Distance in meters/)
  end

  it 'should have an input for the time taken' do
    render
    expect(rendered).to match(/Time/)
  end

  it 'should have an input for the rest' do
    render
    expect(rendered).to match(/Rest/)
  end

end
