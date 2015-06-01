require 'rails_helper'

RSpec.describe DistanceRun, :type => :model do
  it "should be deleted when the distance workout is deleted" do
    original_distance_run_count = DistanceRun.count
    distance_workout = DistanceWorkout.create
    distance_run = DistanceRun.new
    distance_run.distance_workout = distance_workout
    distance_run.save
    expect(DistanceRun.count).to eq(original_distance_run_count + 1)
    distance_workout.destroy
    expect(DistanceRun.count).to eq(original_distance_run_count)
  end
end
