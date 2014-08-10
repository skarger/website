class AddNotesToWorkouts < ActiveRecord::Migration
  def change
    add_column :workouts, :notes, :string
  end
end
