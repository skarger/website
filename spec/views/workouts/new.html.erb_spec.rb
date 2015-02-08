require "rails_helper"

RSpec.describe "workouts/new", :type => :view do
  it "should have an input for where the workout occurred" do
    @workout = Workout.new
    render
    expect(rendered).to match /Where/
  end

  it "should have an input for when the workout occurred" do
    @workout = Workout.new
    render
    expect(rendered).to match /When/
  end

  it "should have an input for the workout type" do
    @workout = Workout.new
    render
    expect(rendered).to match /Type/
  end

  it "should have an input for notes" do
    @workout = Workout.new
    render
    expect(rendered).to match /Notes/
  end
end