require 'rails_helper'

RSpec.describe "Workouts", :type => :request do
  describe "GET /workouts" do
    context "when not logged in" do
      it "should not show the Add Workout link" do
        get workouts_path
        expect(response.body).to_not include("Add new workout")
      end
    end

    context "when logged in" do
      it "should show the Add Workout link" do
        allow_any_instance_of(WorkoutsController).
          to receive(:logged_in?).and_return(true)
        get workouts_path
        expect(response.body).to include("Add new workout")
      end
    end
  end
end
