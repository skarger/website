require "rails_helper"

RSpec.describe "workouts/new", :type => :view do
  before(:each) do
    @workout = Workout.new
  end

  it "should have an input for where the workout occurred" do
    render
    expect(rendered).to match /Where/
  end

  it "should have an input for when the workout occurred" do
    render
    expect(rendered).to match /When/
  end

  context "when the date differs between US/Eastern and UTC" do
    it "should show the US/Eastern version for the default workout date" do
      may31_eastern_june1_utc = Time.new(2015, 5, 31, 23, 0, 0, "-04:00")
      allow(Time).to receive(:now).and_return(may31_eastern_june1_utc)
      render
      day = assert_select("select#workout_when_3i option[selected]").
        first['value']
      expect(day).to eq("31")
    end
  end

  context "when the date differs between US/Eastern and US/Central" do
    it "should show the US/Eastern version for the default workout date" do
      may31_central_june1_eastern = Time.new(2015, 5, 31, 23, 0, 0, "-05:00")
      allow(Time).to receive(:now).and_return(may31_central_june1_eastern)
      render
      day = assert_select("select#workout_when_3i option[selected]").
        first["value"]
      expect(day).to eq("1")
    end
  end

  it "should have an input for the workout type" do
    render
    expect(rendered).to match /Type/
  end

  it "should have choices for the workout type" do
    render
    given_options = assert_select("select#workout_type option")
    given_values = given_options.collect { |option| option["value"] }
    expect(given_values).to match_array(["SpeedWorkout", "DistanceRun"])
  end

  it "should have an input for notes" do
    render
    expect(rendered).to match /Notes/
  end
end