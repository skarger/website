class RenameSpeedWorkoutToTrackWorkout < ActiveRecord::Migration[5.0]
  def change
    execute("update workouts set type = 'TrackWorkout' where type = 'SpeedWorkout'")
    rename_column(:run_intervals, :speed_workout_id, :track_workout_id)
  end
end
