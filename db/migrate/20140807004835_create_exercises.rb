class CreateExercises < ActiveRecord::Migration
  def change
    create_table :exercises do |t|
      t.belongs_to :workout
      t.string :name
      t.column :category, :integer, default: 0

      t.timestamps
    end
  end
end
