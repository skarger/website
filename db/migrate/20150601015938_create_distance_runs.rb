class CreateDistanceRuns < ActiveRecord::Migration
  def change
    create_table :distance_runs do |t|
      t.decimal :distance_in_miles
      t.string :time
      t.integer :distance_workout_id

      t.timestamps null: false
    end

    add_index :distance_runs, :distance_workout_id
    add_foreign_key :distance_runs, :workouts, column: :distance_workout_id, on_delete: :cascade
  end
end
