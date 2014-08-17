class DropExercises < ActiveRecord::Migration
  def change
    drop_table :exercises
  end
end
