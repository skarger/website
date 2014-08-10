class CreateWorkouts < ActiveRecord::Migration
  def change
    create_table :workouts do |t|
      t.timestamp :when
      t.string :where

      t.timestamps
    end
  end
end
