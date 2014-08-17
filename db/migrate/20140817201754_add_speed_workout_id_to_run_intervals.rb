class AddSpeedWorkoutIdToRunIntervals < ActiveRecord::Migration
  def change
    add_column :run_intervals, :speed_workout_id, :integer
  end
end
