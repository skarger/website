class RemoveExerciseIdFromRunInterval < ActiveRecord::Migration
  def change
    remove_column :run_intervals, :exercise_id, :integer
  end
end
