class RenameRunIntervalToTrackInterval < ActiveRecord::Migration[5.0]
  def change
    rename_table :run_intervals, :track_intervals
  end
end
